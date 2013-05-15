#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <time.h>
#include <fstream>
#include "Fitness.h"
#include "CudaEval.h"

#define POPULATION_SIZE 200 // number of members in a population
#define POPULATION_PADDING 1500 // number of extra members to make for padding
#define CHROMOSOME_LENGTH 903 // length of bitstring representation of graph
#define CROSSES 200000 // number of crosses to complete before starting over
#define START_CLIMBING 5000 // number of crosses to complete before climbing
#define START_MUTATION 50000 // number of crosses to complete before mutating
#define MUTATION_PERCENTAGE .1 // percent of bits to flip during mutation
#define CROSSOVER_FUNCTIONS 2 // number of crossovers
#define CROSSOVER_RANDOMIZATION_POINT 300 // score at which to randomize crossover

/* Single member of the population. Contains bitstring and score */
typedef struct member_struct {
    char* chromosome;
    int num_cliques;
} MEMBER;

void InitializePopulation(MEMBER[]);
void PadPopulation(MEMBER[]);
void PrintPopulation(MEMBER[]);
void QuicksortPopulation(MEMBER[], int, int);
void Cross(MEMBER*, MEMBER*, MEMBER*);
void InitializeRandomMember(MEMBER*);
void InsertMemberIntoPopulation(MEMBER, MEMBER[]);
void CrossWithBias(MEMBER[2], MEMBER*);
void CrossAtRandomSinglePoint(MEMBER[2], MEMBER*);
void Breed(MEMBER[], void (*Cross[CROSSOVER_FUNCTIONS])(MEMBER[2], MEMBER*));
void Mutate(MEMBER*);
void Climb(MEMBER*);
int EvaluateAdjacencyMatrix(char[N][N]);


int main(int argc, const char* argv[])
{	
	/* init crossover pointers */
	void (*Cross[CROSSOVER_FUNCTIONS])(MEMBER[2], MEMBER*) = {NULL};
	Cross[0] = &CrossWithBias;
	Cross[1] = &CrossAtRandomSinglePoint;
	
	/* init random seed */
	unsigned int seed = time(NULL);
	srand(seed);

	/* init cache of subsets on device */
	CudaInit();

	/* loops entire algorithm until halted */
	while (1) {

		MEMBER population[POPULATION_SIZE];

		/* initialize, pad, and print population */
		InitializePopulation(population);
		PadPopulation(population);
		PrintPopulation(population);

		/* do the work of actually breeding population */
		Breed(population, Cross);

		std::ofstream file;
		file.open("ramsey.txt", std::ios::app);
		file << "BEST: " << population[0].num_cliques << std::endl;
		file << "ENCODING: " << std::endl;
		for (int j = 0; j < CHROMOSOME_LENGTH; j++) {
			file << (char) (population[0].chromosome[j] + 0x30);
		}
		file << std::endl;
		file << "SEED: " << seed << std::endl << std::endl;
		file.close();

		for (int z = 0; z < POPULATION_SIZE; z++) {
			free(population[z].chromosome);
		}
	}
}

/*
 * Sets each space in a population array to a new random member
 */
void InitializePopulation(MEMBER population[])
{
	std::cout << "INITIALIZING POPULATION" << std::endl;
	for (int i = 0; i < POPULATION_SIZE; i++) {
		InitializeRandomMember(&population[i]);
	}
	QuicksortPopulation(population, 0, POPULATION_SIZE - 1);
}

/*
 * Pads population with ramdom members in hopes of getting
 * a more fit pool with which to begin.
 */
void PadPopulation(MEMBER population[])
{
	std::cout << "PADDING POPULATION" << std::endl << std::endl;

	for (int i = 0; i < POPULATION_PADDING; i++) {
		MEMBER member;
		InitializeRandomMember(&member);
		InsertMemberIntoPopulation(member, population);
	}
}

/*
 * Prints scores for an array of MEMBER.
 */
void PrintPopulation(MEMBER population[])
{
    for (int i = 0; i < POPULATION_SIZE; i++) {
        std::cout << "Member " << std::setw(3) << i + 1 << ": " ;
        std::cout << std::setw(4) << population[i].num_cliques << std::endl;
    }
    std::cout << std::endl;
}

/*
 * Performs a quicksort on an array of MEMBER.
 */
void QuicksortPopulation(MEMBER population[], int left, int right)
{
    int i = left;
    int j = right;
    int pivot = population[(left + right) / 2].num_cliques;
    MEMBER temp;

    /* partition */
    while (i <= j) {
        while (population[i].num_cliques < pivot) {
            i++;
        }
        while (population[j].num_cliques > pivot) {
            j--;
        }
        if (i <= j) {
            temp = population[i];
            population[i] = population[j];
            population[j] = temp;
            i++;
            j--;
        }
    };

    /* recursively sort either side of pivot */
    if (left < j) {
        QuicksortPopulation(population, left, j);
    }
    if (i < right) {
        QuicksortPopulation(population, i, right);
    }

    return;
}

void InsertMemberIntoPopulation(MEMBER member, MEMBER population[])
{
	if (member.num_cliques < population[POPULATION_SIZE - 1].num_cliques) {
		free(population[POPULATION_SIZE - 1].chromosome);
		population[POPULATION_SIZE - 1] = member;
		for (int i = POPULATION_SIZE - 1; i > 0; i--) {
			if (population[i].num_cliques < population[i - 1].num_cliques) {
				population[i] = population[i - 1];
				population[i - 1] = member;
			} else {
				break;
			}
		}
	} else {
		free(member.chromosome);
	}
}

void InitializeRandomMember(MEMBER *member)
{
    char *child_chromosome = (char*)(malloc(sizeof(char) * CHROMOSOME_LENGTH));
    for (int i = 0; i < CHROMOSOME_LENGTH; i++) {
        child_chromosome[i] = rand() % 2;
    }

	char adjacency_matrix[N][N];
    GetAdjacencyMatrixFromCharArray(child_chromosome, adjacency_matrix);
    int num_cliques = EvaluateAdjacencyMatrix(adjacency_matrix);
    member->chromosome = child_chromosome;
    member->num_cliques = num_cliques;
}

void Breed(MEMBER population[], void (*Cross[CROSSOVER_FUNCTIONS])(MEMBER[2], MEMBER*))
{
	std::cout << "BREEDING" << std::endl << std::endl;

	/* breed children */
	int best = 999999;
	for (int i = 0; i < CROSSES; i++) {
		if (i > START_CLIMBING && i % 500 == 0) {
			std::cout << "CLIMBING" << std::endl;
			for (int j = 0; j < POPULATION_SIZE; j++) {
				Climb(&population[j]);
			}
			QuicksortPopulation(population, 0, POPULATION_SIZE - 1);
			if (population[0].num_cliques < best) {
				best = population[0].num_cliques;
				std::cout << "Current best (H): " << best << std::endl;
			}
		}
		if (i > START_MUTATION && i % 2000 == 0) {
			std::cout << "MUTATING" << std::endl;
			int x;
			for (int j = 0; j < (int) ((float) POPULATION_SIZE * 0.25); j++) {
				x = rand() % (POPULATION_SIZE - 5) + 5;
				Mutate(&population[x]);
			}
		}
		
		MEMBER parents[2];
		MEMBER child;
		
		parents[0] = population[rand() % ((int) ((float) POPULATION_SIZE * 0.3))];
		parents[1] = population[rand() % (((int) ((float) POPULATION_SIZE * 0.7)) + ((int) ((float) POPULATION_SIZE * 0.3)))];
		
		int cross = population[0].num_cliques < CROSSOVER_RANDOMIZATION_POINT? rand() % 2 : 0;
		(*Cross[cross])(parents, &child);
		InsertMemberIntoPopulation(child, population);
		
		if (population[0].num_cliques < best) {
			best = population[0].num_cliques;
			std::cout << "Current best (X): " << best << std::endl;
		}

		/* NOT GOING TO HAPPEN */
		if (best < 10) {
			std::cout << population[0].num_cliques << ":" << std::endl;

			for (int j = 0; j < CHROMOSOME_LENGTH; j++) {
				std::cout << (char) (population[0].chromosome[j] + 0x30);
			}
			
			std::cout << std::endl;
		}

		if (population[POPULATION_SIZE - 1].num_cliques == population[0].num_cliques) {
			std::cout << "MIGRATING" << std::endl;
			for (int j = (int) ((float) POPULATION_SIZE * 0.05); j < POPULATION_SIZE; j++) {
				free(population[j].chromosome);
				InitializeRandomMember(&population[j]);
			}
			QuicksortPopulation(population, 0, POPULATION_SIZE - 1);
		}
	}

	std::cout << std::endl;
	PrintPopulation(population);
	std::cout << "Best member: " << population[0].num_cliques << std::endl;
	
	for (int j = 0; j < CHROMOSOME_LENGTH; j++) {
		std::cout << (char) (population[0].chromosome[j] + 0x30);
	}
}

void Mutate(MEMBER *member) {
	int bit;
	for (int i = 0; i < (int) CHROMOSOME_LENGTH * MUTATION_PERCENTAGE; i++) {
		bit = rand() % CHROMOSOME_LENGTH;
		member->chromosome[bit] ^= 1;
	}
}

void Climb(MEMBER *member) {
	
	int bit = rand() % CHROMOSOME_LENGTH;
	member->chromosome[bit] ^= 1;

	char adjacency_matrix[N][N];
    GetAdjacencyMatrixFromCharArray(member->chromosome, adjacency_matrix);
    int num_cliques = EvaluateAdjacencyMatrix(adjacency_matrix);

	if (num_cliques < member->num_cliques) {
		member->num_cliques = num_cliques;
	} else {
		member->chromosome[bit] ^= 1;
	}
}

void CrossWithBias(MEMBER parents[2], MEMBER *child)
{
    char *child_chromosome = (char*)(malloc(sizeof(char) * CHROMOSOME_LENGTH));

	float bias;
	float parent_cliques[2];
	parent_cliques[0] = (float)parents[0].num_cliques;
	parent_cliques[1] = (float)parents[1].num_cliques;

	bias = parent_cliques[parent_cliques[0] < parent_cliques[1]] / (parent_cliques[0] + parent_cliques[1]);
	MEMBER bad;
	MEMBER good;
	if (parent_cliques[0] < parent_cliques[1]) {
		bad = parents[1];
		good = parents[0];
	} else {
		bad = parents[0];
		good = parents[1];
	}

	for (int i = 0; i < CHROMOSOME_LENGTH; i++) {
		if (((float)rand() / (float)RAND_MAX) > bias) {
			child_chromosome[i] = bad.chromosome[i];
		} else {
			child_chromosome[i] = good.chromosome[i];
		}
	}

	char adjacency_matrix[N][N];
    GetAdjacencyMatrixFromCharArray(child_chromosome, adjacency_matrix);
    int num_cliques = EvaluateAdjacencyMatrix(adjacency_matrix);

    child->chromosome = child_chromosome;
    child->num_cliques = num_cliques;
}

void CrossAtRandomSinglePoint(MEMBER parents[2], MEMBER *child)
{
	/*char *chromosome[2];
    chromosome[0] = parents[0].chromosome;
    chromosome[1] = parents[1].chromosome;*/

    char *child_chromosome = (char*)(malloc(sizeof(char) * CHROMOSOME_LENGTH));
	char *child_chromosome2 = (char*)(malloc(sizeof(char) * CHROMOSOME_LENGTH));

    int crossover = rand() % CHROMOSOME_LENGTH;
    
	for (int i = 0; i < crossover; i++) {
        //child_chromosome[i] = chromosome[0][i];
		child_chromosome[i] = parents[0].chromosome[i];
		child_chromosome2[i] = parents[1].chromosome[i];
	}

    for (int i = crossover; i < CHROMOSOME_LENGTH; i++) {
        //child_chromosome[i] = chromosome[1][i];
		child_chromosome[i] = parents[1].chromosome[i];
		child_chromosome2[i] = parents[0].chromosome[i];
    }

	char adjacency_matrix[N][N];
    GetAdjacencyMatrixFromCharArray(child_chromosome, adjacency_matrix);
    int num_cliques = EvaluateAdjacencyMatrix(adjacency_matrix);

	char adjacency_matrix2[N][N];
	GetAdjacencyMatrixFromCharArray(child_chromosome2, adjacency_matrix2);
	int num_cliques2 = EvaluateAdjacencyMatrix(adjacency_matrix);

	if (num_cliques < num_cliques2) {
		child->chromosome = child_chromosome;
		child->num_cliques = num_cliques;
	} else {
		child->chromosome = child_chromosome2;
		child->num_cliques = num_cliques2;
	}
}

int EvaluateAdjacencyMatrix(char adj[N][N]) {
	return CudaEval((char *) adj);
}
