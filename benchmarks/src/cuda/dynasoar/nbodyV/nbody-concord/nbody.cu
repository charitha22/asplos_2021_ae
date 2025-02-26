#include <curand_kernel.h>
#include <stdio.h>
#include <chrono>

#define ALL __noinline__ __host__ __device__
#define CONCORD(ptr, fun, arg)    \
    if (ptr->classType == 0)      \
        ptr->Base##fun arg;       \
    else if (ptr->classType == 1) \
        ptr->fun arg;

#define CONCORDR(r, ptr, fun, arg) \
    if (ptr->classType == 0)       \
        r = ptr->Base##fun arg;    \
    else if (ptr->classType == 1)  \
        r = ptr->fun arg;
#include "../configuration.h"

#define gpuErrchk(ans) \
    { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line,
                      bool abort = true) {
    if (code != cudaSuccess) {
        fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file,
                line);
        if (abort) exit(code);
    }
}

static const int kCudaBlockSize = 256;
class BodyType {
  public:
    float pos_x;
    float pos_y;
    float vel_x;
    float vel_y;
    float mass;
    float force_x;
    float force_y;
    int classType = 0;

  public:
    __noinline__ __device__ void BaseinitBody(int idx) {
        curandState rand_state;
        curand_init(kSeed, idx, 0, &rand_state);

        pos_x = 2 * curand_uniform(&rand_state) - 1;
        pos_y = 2 * curand_uniform(&rand_state) - 1;
        vel_x = (curand_uniform(&rand_state) - 0.5) / 1000;
        vel_y = (curand_uniform(&rand_state) - 0.5) / 1000;
        mass = (curand_uniform(&rand_state) / 2 + 0.5) * kMaxMass;
    }
    ALL BodyType() {classType = 0; }
    __noinline__ __host__ __device__ BodyType(int idx) { classType = 0; }
    
    ALL float BasecomputeDistance(BodyType *other) {
        float dx;
        float dy;
        float dist;
        dx = this->pos_x - other->pos_x;
        dy = this->pos_y - other->pos_y;
        dist = sqrt(dx * dx + dy * dy);
        return dist;
    }
    ALL float BasecomputeForce(BodyType *other, float dist) {
        float F = kGravityConstant * this->mass * other->mass /
                  (dist * dist + kDampeningFactor);
        return F;
    }
    ALL void BaseupdateVelX() { this->vel_x += this->force_x * kDt / this->mass; }
    ALL void BaseupdateVelY() { this->vel_y += this->force_y * kDt / this->mass; }
    ALL void BaseupdatePosX() { this->pos_x += this->vel_x * kDt; }
    ALL void BaseupdatePosY() { this->pos_y += this->vel_y * kDt; }
    ALL void BaseinitForce() {
        this->force_x = 0;
        this->force_y = 0;
    }
    ALL void BaseupdateForceX(BodyType *other, float F) {
        float dx;
        float dy;
        float dist;
        dx = -1 * (this->pos_x - other->pos_x);
        dy = -1 * (this->pos_y - other->pos_y);
        dist = sqrt(dx * dx + dy * dy);
        this->force_x += F * dx / dist;
    }
    ALL void BaseupdateForceY(BodyType *other, float F) {
        float dx;
        float dy;
        float dist;
        dx = -1 * (this->pos_x - other->pos_x);
        dy = -1 * (this->pos_y - other->pos_y);
        dist = sqrt(dx * dx + dy * dy);
        this->force_y += F * dy / dist;
    }

    void Baseadd_checksum(){}


    // Only for rendering.
    ALL float Basepos_x_() const { return pos_x; }
    ALL float Basepos_y_() const { return pos_y; }
    ALL float Basemass_() const { return mass; }

    ////////////

    __noinline__ __device__ void initBody(int idx) {
        curandState rand_state;
        curand_init(kSeed, idx, 0, &rand_state);

        pos_x = 2 * curand_uniform(&rand_state) - 1;
        pos_y = 2 * curand_uniform(&rand_state) - 1;
        vel_x = (curand_uniform(&rand_state) - 0.5) / 1000;
        vel_y = (curand_uniform(&rand_state) - 0.5) / 1000;
        mass = (curand_uniform(&rand_state) / 2 + 0.5) * kMaxMass;
    }

    ALL float computeDistance(BodyType *other) {
        float dx;
        float dy;
        float dist;
        dx = this->pos_x - other->pos_x;
        dy = this->pos_y - other->pos_y;
        dist = sqrt(dx * dx + dy * dy);
        return dist;
    }
    ALL float computeForce(BodyType *other, float dist) {
        float F = kGravityConstant * this->mass * other->mass /
                  (dist * dist + kDampeningFactor);
        return F;
    }
    ALL void updateVelX() { this->vel_x += this->force_x * kDt / this->mass; }
    ALL void updateVelY() { this->vel_y += this->force_y * kDt / this->mass; }
    ALL void updatePosX() { this->pos_x += this->vel_x * kDt; }
    ALL void updatePosY() { this->pos_y += this->vel_y * kDt; }
    ALL void initForce() {
        this->force_x = 0;
        this->force_y = 0;
    }
    ALL void updateForceX(BodyType *other, float F) {
        float dx;
        float dy;
        float dist;
        dx = -1 * (this->pos_x - other->pos_x);
        dy = -1 * (this->pos_y - other->pos_y);
        dist = sqrt(dx * dx + dy * dy);
        this->force_x += F * dx / dist;
    }
    ALL void updateForceY(BodyType *other, float F) {
        float dx;
        float dy;
        float dist;
        dx = -1 * (this->pos_x - other->pos_x);
        dy = -1 * (this->pos_y - other->pos_y);
        dist = sqrt(dx * dx + dy * dy);
        this->force_y += F * dy / dist;
    }

    void add_checksum();

    // Only for rendering.
    ALL float pos_x_() const { return pos_x; }
    ALL float pos_y_() const { return pos_y; }
    ALL float mass_() const { return mass; }
};
class Body : public BodyType {
  public:
    __noinline__ __host__ __device__ Body() { classType = 1; }
    __noinline__ __host__ __device__ Body(int idx) { classType = 1; }
};

__device__ float device_checksum;

__global__ void Body_compute_force(BodyType **dev_bodies) {
    int id = threadIdx.x + blockDim.x * blockIdx.x;
    float dist;
    float F;
    if (id < kNumBodies) {
        CONCORD(dev_bodies[id], initForce, ());

        // printf("%d ddd\n", id);
        for (int i = 0; i < kNumBodies; ++i) {
            // Do not compute force with the body itself.
            if (id != i) {
                CONCORDR(dist, dev_bodies[id], computeDistance,
                         (dev_bodies[i]));
                CONCORDR(F, dev_bodies[id], computeForce,
                         (dev_bodies[i], dist));
                CONCORD(dev_bodies[id], updateForceX, (dev_bodies[i], F));
                CONCORD(dev_bodies[id], updateForceY, (dev_bodies[i], F));
            }
        }
    }
}

__global__ void Body_update(BodyType **dev_bodies) {
    int id = threadIdx.x + blockDim.x * blockIdx.x;

    if (id < kNumBodies) {
        CONCORD(dev_bodies[id], updateVelX, ());
        CONCORD(dev_bodies[id], updateVelY, ());
        CONCORD(dev_bodies[id], updatePosX, ());
        CONCORD(dev_bodies[id], updatePosY, ());

        if (dev_bodies[id]->pos_x < -1 || dev_bodies[id]->pos_x > 1) {
            dev_bodies[id]->vel_x = -dev_bodies[id]->vel_x;
        }

        if (dev_bodies[id]->pos_y < -1 || dev_bodies[id]->pos_y > 1) {
            dev_bodies[id]->vel_y = -dev_bodies[id]->vel_y;
        }
    }
}

__device__ void Body_add_checksum(BodyType **dev_bodies, int id) {
    atomicAdd(&device_checksum,
              dev_bodies[id]->pos_x + dev_bodies[id]->pos_y * 2 +
                  dev_bodies[id]->vel_x * 3 + dev_bodies[id]->vel_y * 4);
}

__global__ void kernel_initialize_bodies(BodyType **bodies) {
    for (int i = threadIdx.x + blockDim.x * blockIdx.x; i < kNumBodies;
         i += blockDim.x * gridDim.x) {
        bodies[i] = new Body(/*idx*/ i);
        CONCORD(bodies[i],initBody,(i));
    }
}

__global__ void kernel_compute_force() {
    for (int i = threadIdx.x + blockDim.x * blockIdx.x; i < kNumBodies;
         i += blockDim.x * gridDim.x) {
        // Body_compute_force(i);
    }
}

__global__ void kernel_update() {
    for (int i = threadIdx.x + blockDim.x * blockIdx.x; i < kNumBodies;
         i += blockDim.x * gridDim.x) {
        // Body_update(i);
    }
}

__global__ void kernel_compute_checksum(BodyType **bodies) {
    device_checksum = 0.0f;
    for (int i = 0; i < kNumBodies; ++i) {
        Body_add_checksum(bodies, i);
    }
}

// void print_ptr_diff(BodyType **ptr) {
//     int i;
//     for (i = 1; i < kNumBodies / 100; i++) {
//       unsigned long long ptr2=(unsigned long long)ptr[i];
//       unsigned long long ptr1=(unsigned long long)ptr[i-1];
//         printf("[ptr[%d]-ptr[%d]]= %ull\n", i, i - 1,
//     (ptr2-  ptr1 ));
//     }
//   }
int main(int /*argc*/, char ** /*argv*/) {
    BodyType **dev_bodies;

    // Allocate and create Body objects.
    cudaMallocManaged(&dev_bodies, sizeof(BodyType *) * kNumBodies);
    printf("init bodies...\n");
    kernel_initialize_bodies<<<128, 128>>>(dev_bodies);

    gpuErrchk(cudaDeviceSynchronize());

    printf("init done...\n");
    auto time_start = std::chrono::system_clock::now();
    printf("Kernel exec...\n");
    for (int i = 0; i < kNumIterations; ++i) {
        if (i % 300 == 0) printf("Start: BodyComputeForce(%d)\n", i);
        Body_compute_force<<<(kNumBodies + kCudaBlockSize - 1) / kCudaBlockSize,
                             kCudaBlockSize>>>(dev_bodies);
        gpuErrchk(cudaDeviceSynchronize());
        // printf("Body_compute_force(%d)\n",i);
        Body_update<<<(kNumBodies + kCudaBlockSize - 1) / kCudaBlockSize,
                      kCudaBlockSize>>>(dev_bodies);
        gpuErrchk(cudaDeviceSynchronize());
        if (i % 300 == 0) printf("Finish: BodyComputeForce(%d)\n", i);
    }

    auto time_end = std::chrono::system_clock::now();
    auto elapsed = time_end - time_start;
    auto micros =
        std::chrono::duration_cast<std::chrono::microseconds>(elapsed).count();

    printf("%lu\n", micros);

#ifndef NDEBUG
    kernel_compute_checksum<<<1, 1>>>(dev_bodies);
    gpuErrchk(cudaDeviceSynchronize());

    float checksum;
    cudaMemcpyFromSymbol(&checksum, device_checksum, sizeof(device_checksum), 0,
                         cudaMemcpyDeviceToHost);
    printf("Checksum: %f\n", checksum);
#endif  // NDEBUG

    cudaFree(dev_bodies);

    return 0;
}
