/* Fitness function to evaluate the number of monochromatic 
 * cliques present in a given graph.
 *
 * Jon Johnson, Gabriel Triggs
 */
#include <iostream>
#include <stdlib.h>
#include <string>
#include <time.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include "Fitness.h"



//global variables
std::string bit_string = "011001110000011100100001110110000000010100110010010111110111010100111111110100011001000010011001111100101011111000001010011101101110100101011001100110001101101000000011000010110100011111001110100010101011001110010001110000111101000101010111100100000101110111101101011010000011000110001101001110110110111001011001101011110100011111011010001100010100010100101011110101100010001100101111011011000010110000101001001010101000101110110111110011101100001000100011111011101001010101111010101110011010001111000110111010011011001001011001100000000100110010111111100010010001011010110011010101001110010100111001001011100100100100100010110011110000100101010111110101101000001111001111101100011111001010101000010011001110100100011100101011000011100010101110011101111000101000110001010100100111100101111011010100001100010010101011000100010101110101010111101001110000110110101001000010011110111001100101111011100001010";
char *char_bits = new char[bit_string.size()];
int adjacency_matrix[N][N];

void print()
{
    std::cout << "test" << std::endl;
    std::cin >> "%d";
}

//int main(int argc, char *argv[])
//{
//    /* init char_bits */
//    for (int i = 0; i < bit_string.size(); i++) {
//        char_bits[i] = (bit_string[i] == '0') ? 0 : 1;
//    }
//
//    GetAdjacencyMatrixFromCharArray(char_bits, adjacency_matrix);
//
//    srand (time(NULL)); // init random seed
//    int upper_bound = choose_cache[N][K];
//    std::cout << upper_bound << std::endl;
//    int arr[5] = { 0, 0, 0, 0, 0 };
//
//
//
// //   // need to figure out time stuff
// //   long total_time = 0;
// //   long first_time = time(NULL); // get current time
// //   long time_limit = 5;
//  //int count = 0;
// //   do {
// //       int num_cliques = 0;
//
// //       /* evaluate every possible clique */
// //       for (int i = 0; i < upper_bound; i++) {
// //           GetElement(i, arr);
// //           
// //           int result = EvaluateEdges(arr);
// //           
// //           if (result == 0 || result == KC2) {
// //               num_cliques++;
// //               //print();
// //           }
// //       }
//
// //       long current_time = time(NULL);
// //       total_time = current_time - first_time;
// //       
// //       std::cout << "Cliques: " << num_cliques << std::endl;
//
// //       if (num_cliques < 10) {
// //           /* not going to happen */
// //           for (int j = 0; j < bit_string.size(); j++) {
// //               std::cout << char_bits[j];
// //           }
// //           std::cout << std::endl;
// //       }
//
// //       /* flip a random bit */
// //       int x = rand() % bit_string.size(); // random number over [0, char_bits.length)
// //       char_bits[x] = !char_bits[x];
// //       GetAdjacencyMatrixFromCharArray(char_bits, adjacency_matrix);
//  //  count++;
// //   } while (total_time < 5);
//  //std::cout << "Number of graphs processed: " << count << std::endl;
//  //std::cout << "Time per graph: " << total_time / (float)count << std::endl;
//  std::getchar();
//}

/*
 * Returns the number of edges in arr that are "red" (1).
 *
 * If this return KC2, it is a red clique.
 * If this returns 0, it is a blue clique.
 */
int EvaluateEdges(int arr[])
{
    return adjacency_matrix[arr[0]][arr[1]] +
           adjacency_matrix[arr[0]][arr[2]] +
           adjacency_matrix[arr[0]][arr[3]] +
           adjacency_matrix[arr[0]][arr[4]] +
           adjacency_matrix[arr[1]][arr[2]] +
           adjacency_matrix[arr[1]][arr[3]] +
           adjacency_matrix[arr[1]][arr[4]] +
           adjacency_matrix[arr[2]][arr[3]] +
           adjacency_matrix[arr[2]][arr[4]] +
           adjacency_matrix[arr[3]][arr[4]];
}

/*
 * Populates adjacency matrix based on contents of char array.
 */
void GetAdjacencyMatrixFromCharArray(char bit_arr[], int adj[N][N])
{
    int x = 0;

    for (int i = 0; i < N; i++) {
        for (int j = i + 1; j < N; j++) {
            adj[i][j] = bit_arr[x];
            adj[j][i] = bit_arr[x];
            x++;
        }
    }
}

/*
 *Populates arr with the mth lexicographic subset of size K from N vertices.
 */
void GetElement(int m, int arr[])
{
    int a = N;
    int b = K;
    int x = (choose_cache[N][K] - 1) - m; // x is the "dual" of m

    for (int i = 0; i < K; i++) {
        arr[i] = GetLargestV(a, b, x); //largest value v where v < a and vCb < x
        x = x - choose_cache[arr[i]][b];
        a = arr[i];
        b--;
    }

    for (int i = 0; i < K; i++) {
        arr[i] = (N - 1) - arr[i];
    }
}

/*
 * Returns largest value v where v < a and vCb <= x
 */
int GetLargestV(int a, int b, int x)
{
    int v = a - 1;

    while (choose_cache[v][b] > x) {
        v--;
    }

    return v;
    
}

