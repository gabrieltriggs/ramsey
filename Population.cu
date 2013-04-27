#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <time.h>
#include "Fitness.h"

#define POPULATION_SIZE 150
#define POPULATION_PADDING 500
#define CHROMOSOME_LENGTH 903

typedef struct member_struct {
    char* chromosome;
    int num_cliques;
} MEMBER;

void PrintPopulation(MEMBER[]);
void SortInitialPopulation(MEMBER[], int, int);
void Cross(MEMBER*, MEMBER*, MEMBER*);
void InitializeRandomMember(MEMBER*);
void printMatrix(int[N][N]);
void InsertMember(MEMBER[], MEMBER);

int main(int argc, const char* argv[])
{
    srand(time(NULL)); //init random seed

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
		//PrintPopulation(population);
	}
	PrintPopulation(population);

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
		population[POPULATION_SIZE - 1] = member;
		for (int i = POPULATION_SIZE - 1; i > 0; i--) {
			if (population[i].num_cliques < population[i - 1].num_cliques) {
				population[i] = population[i - 1];
				population[i - 1] = member;
			} else {
				break;
			}
		}
	}
}

void InitializeRandomMember(MEMBER *member)
{
    char *child_chromosome = (char*)(malloc(sizeof(char) * CHROMOSOME_LENGTH + 1));
	char *char_bits = new char[CHROMOSOME_LENGTH];
    for (int i = 0; i < CHROMOSOME_LENGTH; i++) {
        child_chromosome[i] = rand() % 2 + 0x30;
		char_bits[i] = child_chromosome[i] - 0x30;
    }

    child_chromosome[903] = '\0';

    int adjacency_matrix[N][N];
    GetAdjacencyMatrixFromCharArray(char_bits, adjacency_matrix);
    int num_cliques = 0;
    /* evaluate every possible clique */
    for (int i = 0; i < UPPER_BOUND; i++) {
		int arr[5] = { 0, 0, 0, 0, 0 };
        GetElement(i, arr);
            
        int result = EvaluateEdges(arr, adjacency_matrix);
            
        if (result == 0 || result == KC2) {
            num_cliques++;
		}
    }
    member->chromosome = child_chromosome;
    member->num_cliques = num_cliques;
}

void printMatrix(int arr[N][N]) {
	for (int i = 0; i < N; i++) {
		for (int j = 0; j < N; j++) {
			std::cout << arr[i][j] << " ";
		}
		std::cout << std::endl;
	}
}

void Cross(MEMBER *mom, MEMBER *pop, MEMBER *child)
{
    char *mom_chromosome = mom->chromosome;
    char *pop_chromosome = pop->chromosome;

    char *child_chromosome = (char*)(malloc(sizeof(char) * 903 + 1));

    int crossover = 2;//rand() % CHROMOSOME_LENGTH;
    for (int i = 0; i < crossover; i++) {
        child_chromosome[i] = mom_chromosome[i];
        printf("%d\n", i);
        std::getchar();
    }
    printf("TEST");
    std::getchar();
    for (int i = crossover; i < CHROMOSOME_LENGTH; i++) {
        child_chromosome[i] = pop_chromosome[i];
    }
    child_chromosome[903] = '\0';
    child->chromosome = child_chromosome;
    child->num_cliques = 0;
}
