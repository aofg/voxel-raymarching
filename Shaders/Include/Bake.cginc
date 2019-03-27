#ifndef SIDE
    #define SIDE 32
    #define SIDE2 1024
    #define DEFAULT_SIZE int3(SIDE, SIDE, SIDE)
#endif



int PackColor(float4 color) {
    int packed = 0;
    packed |= int(floor(clamp(color.r, 0.0, 1.0) * 255)) << 24;
    packed |= int(floor(clamp(color.g, 0.0, 1.0) * 255)) << 16;
    packed |= int(floor(clamp(color.b, 0.0, 1.0) * 255)) <<  8;
    packed |= int(floor(clamp(color.a, 0.0, 1.0) * 255)) <<  0;
    return packed;
}

float4 UnpackColor(int voxel) {
    float4 color;
    color.r = (voxel >> 24 & 0xFF) / 256.0;
    color.g = (voxel >> 16 & 0xFF) / 256.0;
    color.b = (voxel >>  8 & 0xFF) / 256.0;
    color.a = (voxel >>  0 & 0xFF) / 256.0;
    return color;
}

int3 BufferToVoxel(int2 xy, int3 size) {
    return int3(
        xy.x % size.y,
        xy.x / size.y,
        size.z - xy.y // flip depth
    );
}
int3 BufferToVoxel(int2 xy) {
    return BufferToVoxel(xy, DEFAULT_SIZE);
}
int2 VoxelToBuffer(int3 xyz, int3 size) {
    return int2(
        xyz.x + xyz.y * size.x,
        xyz.z
    );
}
int2 VoxelToBuffer(int3 xyz) {
    return VoxelToBuffer(xyz, DEFAULT_SIZE);
}
int2 VoxelToBuffer(int x, int y, int z) {
    return VoxelToBuffer(int3(x, y, z), DEFAULT_SIZE);
}
int BufferToIndex(int2 buffer, int3 size) {
    return buffer.y * size.x * size.y + buffer.x;
}
int BufferToIndex(int2 buffer) {
    return BufferToIndex(buffer, DEFAULT_SIZE);
}


int3 RotateX(int3 xyz) {
    // xyz = int3(xyz.x, xyz.z, (SIDE - 1) - xyz.y);
    xyz = int3(xyz.x, xyz.z, -xyz.y);
    return xyz;
}
int3 RotateY(int3 xyz) {
    // xyz = int3(xyz.z, xyz.y, (SIDE - 1) - xyz.x);
    xyz = int3(xyz.z, xyz.y, -xyz.x);
    return xyz;
}
int3 RotateZ(int3 xyz) {
    // xyz = int3(xyz.y, (SIDE - 1) - xyz.x, xyz.z);
    xyz = int3(xyz.y, -xyz.x, xyz.z);
    return xyz;
}

bool Inside(int3 voxel, int3 size) {
    return (voxel.x >= 0 && voxel.x < size.x && voxel.y >= 0 && voxel.y < size.y && voxel.z >= 0 && voxel.z < size.z);
}

bool Inside(int3 voxel) {
    return Inside(voxel, DEFAULT_SIZE);
}


int3 WorldPositionToChunkPosition(int3 pos, int3 chunkSize) {
    return pos / chunkSize;
}

int3 WorldPositionToChunkPosition(int3 pos) {
    return WorldPositionToChunkPosition(pos, DEFAULT_SIZE);
}

int BufferPtrFromChunkPosition(StructuredBuffer<int> allocationMap, int3 chunkPos, int3 worldSize) {
    int index = chunkPos.x + chunkPos.z * worldSize.x + chunkPos.y * worldSize.x * worldSize.z;
    return allocationMap[index];
}
