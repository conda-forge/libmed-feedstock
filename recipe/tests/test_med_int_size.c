#include <med.h>
#include <stdio.h>
#include <stdlib.h>

// Define MED_INT_ASSERT based on platform
#if defined(_WIN32) || defined(_WIN64)
// It seems that whatever we do on windows the size of MED_INT is always 4
#define MED_INT_ASSERT 4
#else
#define MED_INT_ASSERT 8
#endif

int main() {
    if (sizeof(med_int) != MED_INT_ASSERT) {
        printf("Error: sizeof(med_int) is not %d, but %zu\n", MED_INT_ASSERT, sizeof(med_int));
        return EXIT_FAILURE;
    }
    printf("Success: sizeof(med_int) is %d as expected.\n", MED_INT_ASSERT);
    return EXIT_SUCCESS;
}
