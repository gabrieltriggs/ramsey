#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <time.h>

#define POPULATION_SIZE 20

typedef struct member_struct {
    char* chromosome;
    int num_cliques;
} MEMBER;

void PrintPopulation(MEMBER[]);
void SortPopulation(MEMBER[], int, int);

int main(int argc, const char* argv[])
{
    MEMBER population[POPULATION_SIZE];
    srand(time(NULL));

    for (int i = 0; i < POPULATION_SIZE; i++) {
        population[i].chromosome = "hi\0";
        population[i].num_cliques = rand() % 1000;
        
    }

    PrintPopulation(population);
    SortPopulation(population, 0, POPULATION_SIZE - 1);
    PrintPopulation(population);
    
    /* leave console up until keypress */
    std::getchar();
}

/*
 * Prints an array of MEMBER.
 */
void PrintPopulation(MEMBER population[])
{
    for (int i = 0; i < POPULATION_SIZE; i++) {
        std::cout << "Member " << std::setw(2) << i << ": " ;
        std::cout << std::setw(3) << population[i].num_cliques << std::endl;
    }
    std::cout << std::endl;
}

/*
 * Performs a quicksort on an array of MEMBER.
 */
void SortPopulation(MEMBER population[], int left, int right)
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
        SortPopulation(population, left, j);
    }
    if (i < right) {
        SortPopulation(population, i, right);
    }

    return;
}
