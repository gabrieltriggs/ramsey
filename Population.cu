#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <time.h>
#include <fstream>
#include "Fitness.h"
#include "CudaEval.h"

#define POPULATION_SIZE 150
#define POPULATION_PADDING 1000
#define CHROMOSOME_LENGTH 903
#define CROSSES 100000
#define CROSSOVER_FUNCTIONS 3
#define START_CLIMBING 5000

typedef struct member_struct {
    char* chromosome;
    int num_cliques;
} MEMBER;

void PrintPopulation(MEMBER[]);
void SortInitialPopulation(MEMBER[], int, int);
void Cross(MEMBER*, MEMBER*, MEMBER*);
void InitializeRandomMember(MEMBER*);
void PrintMatrix(int[N][N]);
void InsertMember(MEMBER[], MEMBER);
void BiasedCross(MEMBER[2], MEMBER*);
void BiasederCross(MEMBER[2], MEMBER*);
void RandomSinglePointCross(MEMBER[2], MEMBER*);
void Mutate(MEMBER*);
void Climb(MEMBER*);
int EvalAdj(char[N][N]);

int main(int argc, const char* argv[])
{
	std::ofstream file;
	file.open("ramsey.txt", std::ios::app);
	
	/* init cross pointers */
	void (*Cross[CROSSOVER_FUNCTIONS])(MEMBER[2], MEMBER*) = {NULL};
	Cross[0] = &BiasedCross;
	Cross[1] = &BiasederCross;
	Cross[2] = &RandomSinglePointCross;
	
	unsigned int seed = time(NULL);
    //unsigned int seed = 1367392616;
	srand(seed); //init random seed
	CudaInit();

	std::cout << "INITIALIZING POPULATION" << std::endl;

    MEMBER population[POPULATION_SIZE];

    for (int i = 0; i < POPULATION_SIZE; i++) {
        InitializeRandomMember(&population[i]);
    }

	SortInitialPopulation(population, 0, POPULATION_SIZE - 1);
	PrintPopulation(population);

	std::cout << "PADDING POPULATION" << std::endl << std::endl;

	for (int i = 0; i < POPULATION_PADDING; i++) {
		MEMBER member;
		InitializeRandomMember(&member);
		InsertMember(population, member);
	}
	PrintPopulation(population);

	std::cout << "BREEDING" << std::endl << std::endl;

	/* breed children */
	int best = 999999;
	for (int i = 0; i < CROSSES; i++) {
		
		if (i > START_CLIMBING && i % 500 == 0) {
			std::cout << "CLIMBING" << std::endl;
			for (int j = 0; j < POPULATION_SIZE; j++) {
				Climb(&population[j]);
			}
			SortInitialPopulation(population, 0, POPULATION_SIZE - 1);
			if (population[0].num_cliques < best) {
				best = population[0].num_cliques;
				std::cout << "Current best (H): " << best << std::endl;
			}
		}

		MEMBER parents[2];
		MEMBER child;

		parents[0] = population[rand() % POPULATION_SIZE];
		parents[1] = population[rand() % POPULATION_SIZE];
		(*Cross[0])(parents, &child);

		/*parents[0] = population[rand() % (POPULATION_SIZE / 2)];
		//parents[1] = population[(rand() % (POPULATION_SIZE / 2) + POPULATION_SIZE / 2)];
		//(*Cross[1])(parents, &child);
		//(*Cross[0])(parents, &child);

		/* NOT GOING TO HAPPEN */
		if (child.num_cliques < 10) {
			std::cout << child.num_cliques << ":" << std::endl;

			for (int j = 0; j < CHROMOSOME_LENGTH; j++) {
				std::cout << (char) (child.chromosome[j] + 0x30);
			}

			std::cout << std::endl;
		}

		InsertMember(population, child);

		if (population[0].num_cliques < best) {
			best = population[0].num_cliques;
			std::cout << "Current best (X): " << best << std::endl;
		}

		if (population[POPULATION_SIZE - 1].num_cliques == population[0].num_cliques) {
			std::cout << "MIGRATING" << std::endl;
			for (int j = 5; j < POPULATION_SIZE; j++) {
				free(population[i].chromosome);
				InitializeRandomMember(&population[i]);
			}
		}
	}

	std::cout << std::endl;
	PrintPopulation(population);
	std::cout << "Best member: " << population[0].num_cliques << std::endl;
	for (int j = 0; j < CHROMOSOME_LENGTH; j++) {
		std::cout << (char) (population[0].chromosome[j] + 0x30);
	}

	std::cout << std::endl;

	/* echo seed for posterity */
	std::cout << "SEED: " << seed << std::endl;

	file << "BEST: " << best << std::endl;
	file << "ENCODING: " << std::endl;
	for (int j = 0; j < CHROMOSOME_LENGTH; j++) {
		file << (char) (population[0].chromosome[j] + 0x30);
	}
	file << std::endl;
	file << "SEED: " << seed << std::endl << std::endl;
	file.close();

    /* leave console up until keypress */
	std::cout << "FINISHED AND WAITING FOR RETURN KEY" << std::endl;
    std::getchar();
}

/*
 * Prints an array of MEMBER.
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
void SortInitialPopulation(MEMBER population[], int left, int right)
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
        SortInitialPopulation(population, left, j);
    }
    if (i < right) {
        SortInitialPopulation(population, i, right);
    }

    return;
}

void InsertMember(MEMBER population[], MEMBER member)
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
    int num_cliques = EvalAdj(adjacency_matrix);
    member->chromosome = child_chromosome;
    member->num_cliques = num_cliques;
}

void PrintMatrix(int arr[N][N]) {
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			std::cout << arr[i][j] << " ";
		}
		std::cout << std::endl;
	}
}

void Mutate(MEMBER *member) {
	int bit = rand() % CHROMOSOME_LENGTH;
	member->chromosome[bit] ^= 1;
}

void Climb(MEMBER *member) {
	char *original_chromosome = member->chromosome;
	char *new_chromosome = (char*)(malloc(sizeof(char) * CHROMOSOME_LENGTH));

	for (int i = 0; i < CHROMOSOME_LENGTH; i++) {
		new_chromosome[i] = original_chromosome[i];
	}

	int bit = rand() % CHROMOSOME_LENGTH;
	new_chromosome[bit] ^= 1;

	char adjacency_matrix[N][N];
    GetAdjacencyMatrixFromCharArray(new_chromosome, adjacency_matrix);
    int num_cliques = EvalAdj(adjacency_matrix);

	if (num_cliques < member->num_cliques) {
		member->num_cliques = num_cliques;
		free(member->chromosome);
		member->chromosome = new_chromosome;
	} else {
		free(new_chromosome);
	}
}

void BiasedCross(MEMBER parents[2], MEMBER *child)
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
    int num_cliques = EvalAdj(adjacency_matrix);

    child->chromosome = child_chromosome;
    child->num_cliques = num_cliques;
}

void BiasederCross(MEMBER parents[2], MEMBER *child)
{
	char *chromosome[2];
    chromosome[0] = parents[0].chromosome;
    chromosome[1] = parents[1].chromosome;

    char *child_chromosome = (char*)(malloc(sizeof(char) * CHROMOSOME_LENGTH));

	float bias;
	float parent_cliques[2];
	parent_cliques[0] = (float)parents[0].num_cliques;
	parent_cliques[1] = (float)parents[1].num_cliques;

	bias = parent_cliques[1] / (parent_cliques[0] + parent_cliques[1]);

	for (int i = 0; i < CHROMOSOME_LENGTH; i++) {
		if (((float)rand() / (float)RAND_MAX) > bias) {
			child_chromosome[i] = chromosome[1][i];
		} else {
			child_chromosome[i] = chromosome[0][i];
		}
	}

	char adjacency_matrix[N][N];
    GetAdjacencyMatrixFromCharArray(child_chromosome, adjacency_matrix);
    int num_cliques = EvalAdj(adjacency_matrix);

    child->chromosome = child_chromosome;
    child->num_cliques = num_cliques;
}

void RandomSinglePointCross(MEMBER parents[2], MEMBER *child)
{
	char *chromosome[2];
    chromosome[0] = parents[0].chromosome;
    chromosome[1] = parents[1].chromosome;

    char *child_chromosome = (char*)(malloc(sizeof(char) * CHROMOSOME_LENGTH));

    int crossover = rand() % CHROMOSOME_LENGTH;
    
	for (int i = 0; i < crossover; i++) {
        child_chromosome[i] = chromosome[0][i];
    }

    for (int i = crossover; i < CHROMOSOME_LENGTH; i++) {
        child_chromosome[i] = chromosome[1][i];
    }

	char adjacency_matrix[N][N];
    GetAdjacencyMatrixFromCharArray(child_chromosome, adjacency_matrix);
    int num_cliques = EvalAdj(adjacency_matrix);

    child->chromosome = child_chromosome;
    child->num_cliques = num_cliques;
}

int EvalAdj(char adj[N][N]) {
	return CudaEval((char *) adj);
}
