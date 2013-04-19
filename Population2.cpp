#include <iostream>
#include <iomanip>
#include <stdlib.h>
#include <time.h>

#define POPULATION_SIZE 3
#define CHROMOSOME_LENGTH 16

typedef struct member_struct {
    char* chromosome;
    int num_cliques;
} MEMBER;

void PrintPopulation(MEMBER[]);
void SortPopulation(MEMBER[], int, int);
void Cross(MEMBER*, MEMBER*, MEMBER*);

int main(int argc, const char* argv[])
{
    /*
    MEMBER population[POPULATION_SIZE];
    srand(time(NULL));

    for (int i = 0; i < POPULATION_SIZE; i++) {
        char *chromosome = "1111111111111111\0";
        for (int j = 0; j < CHROMOSOME_LENGTH; j++) {
            if (rand() % 2) {
                chromosome[j] = '0';
            }
        }
        population[i].chromosome = chromosome;
        population[i].num_cliques = rand() % 1000;
        
    }

    PrintPopulation(population);
    SortPopulation(population, 0, POPULATION_SIZE - 1);
    PrintPopulation(population);
    */

    MEMBER population[3];

    //srand(time(NULL));
    population[0].chromosome = "1111111111111111\0";
    population[1].chromosome = "0000000000000000\0";
    population[0].num_cliques = 0;
    population[1].num_cliques = 0;
    
    

    Cross(&population[0], &population[1], &population[2]);

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

void Cross(MEMBER *mom, MEMBER *pop, MEMBER *child)
{
    char *mom_chromosome = mom->chromosome;
    char *pop_chromosome = pop->chromosome;

    char *child_chromosome = (char*)(malloc(sizeof(char) * 16)); //add null char

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
    child->chromosome = child_chromosome;
    child->num_cliques = 0;
}

