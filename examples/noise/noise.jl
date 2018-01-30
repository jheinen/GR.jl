#=

# Perlin noise ported from: https://github.com/caseman/noise
# with the license:

Copyright (c) 2008 Casey Duncan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=#


const F2 = 0.5 * (sqrt(3.0) - 1.0)
const G2 = (3.0 - sqrt(3.0)) / 6.0

const F4 = (sqrt(5.0) - 1.0) / 4.0
const G4 = (5.0 - sqrt(5.0)) / 20.0

const SIMPLEX = [
    (0, 1, 2, 3), (0, 1, 3, 2), (0, 0, 0, 0), (0, 2, 3, 1), (0, 0, 0, 0),
    (0, 0, 0, 0), (0, 0, 0, 0), (1, 2, 3, 0), (0, 2, 1, 3), (0, 0, 0, 0),
    (0, 3, 1, 2), (0, 3, 2, 1), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0),
    (1, 3, 2, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0),
    (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (1, 2, 0, 3),
    (0, 0, 0, 0), (1, 3, 0, 2), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0),
    (2, 3, 0, 1), (2, 3, 1, 0), (1, 0, 2, 3), (1, 0, 3, 2), (0, 0, 0, 0), 
    (0, 0, 0, 0), (0, 0, 0, 0), (2, 0, 3, 1), (0, 0, 0, 0), (2, 1, 3, 0),
    (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0),
    (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (2, 0, 1, 3), (0, 0, 0, 0),
    (0, 0, 0, 0), (0, 0, 0, 0), (3, 0, 1, 2), (3, 0, 2, 1), (0, 0, 0, 0),
    (3, 1, 2, 0), (2, 1, 0, 3), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0),
    (3, 1, 0, 2), (0, 0, 0, 0), (3, 2, 0, 1), (3, 2, 1, 0)
]

const GRAD4 = NTuple{4, Float32}[
    (0, 1, 1, 1), (0, 1, 1, -1), (0, 1, -1, 1), (0, 1, -1, -1), 
    (0, -1, 1, 1), (0, -1, 1, -1), (0, -1, -1, 1), (0, -1, -1, -1), 
    (1, 0, 1, 1), (1, 0, 1, -1), (1, 0, -1, 1), (1, 0, -1, -1), 
    (-1, 0, 1, 1), (-1, 0, 1, -1), (-1, 0, -1, 1), (-1, 0, -1, -1), 
    (1, 1, 0, 1), (1, 1, 0, -1), (1, -1, 0, 1), (1, -1, 0, -1), 
    (-1, 1, 0, 1), (-1, 1, 0, -1), (-1, -1, 0, 1), (-1, -1, 0, -1), 
    (1, 1, 1, 0), (1, 1, -1, 0), (1, -1, 1, 0), (1, -1, -1, 0), 
    (-1, 1, 1, 0), (-1, 1, -1, 0), (-1, -1, 1, 0), (-1, -1, -1, 0)
]

const PERM = [
    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 
    36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 
    234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 
    88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 
    134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 
    230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 
    1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 
    116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 
    124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 
    47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 
    154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 
    108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 
    242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 
    239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 
    50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 
    141, 128, 195, 78, 66, 215, 61, 156, 180, 151, 160, 137, 91, 90, 15, 131, 
    13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 
    240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 
    219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 
    136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 
    231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 
    40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 
    208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 
    173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 
    255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 
    183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 
    43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 
    112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 
    162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 
    106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 
    205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 
    180
]

dot4(v1, x, y, z, w) = ((v1)[1]*(x) + (v1)[2]*(y) + (v1)[3]*(z) + (v1)[4]*(w))

function noise4(x, y, z, w)
    s = (x + y + z + w) * F4
    i = floor(x + s)
    j = floor(y + s)
    k = floor(z + s)
    l = floor(w + s)
    t = (i + j + k + l) * G4

    x0 = x - (i - t)
    y0 = y - (j - t)
    z0 = z - (k - t)
    w0 = w - (l - t)
    c = (x0 > y0)*32 + (x0 > z0)*16 + (y0 > z0)*8 + (x0 > w0)*4 + (y0 > w0)*2 + (z0 > w0)
    c += 1
    i1 = SIMPLEX[c][1] >= 3
    j1 = SIMPLEX[c][2] >= 3
    k1 = SIMPLEX[c][3] >= 3
    l1 = SIMPLEX[c][4] >= 3
    i2 = SIMPLEX[c][1] >= 2
    j2 = SIMPLEX[c][2] >= 2
    k2 = SIMPLEX[c][3] >= 2
    l2 = SIMPLEX[c][4] >= 2
    i3 = SIMPLEX[c][1] >= 1
    j3 = SIMPLEX[c][2] >= 1
    k3 = SIMPLEX[c][3] >= 1
    l3 = SIMPLEX[c][4] >= 1

    x1 = x0 - i1 + G4
    y1 = y0 - j1 + G4
    z1 = z0 - k1 + G4
    w1 = w0 - l1 + G4
    x2 = x0 - i2 + 2.0*G4
    y2 = y0 - j2 + 2.0*G4
    z2 = z0 - k2 + 2.0*G4
    w2 = w0 - l2 + 2.0*G4
    x3 = x0 - i3 + 3.0*G4
    y3 = y0 - j3 + 3.0*G4
    z3 = z0 - k3 + 3.0*G4
    w3 = w0 - l3 + 3.0*G4
    x4 = x0 - 1.0 + 4.0*G4
    y4 = y0 - 1.0 + 4.0*G4
    z4 = z0 - 1.0 + 4.0*G4
    w4 = w0 - 1.0 + 4.0*G4

    I = Int(i) & 255
    J = Int(j) & 255
    K = Int(k) & 255
    L = Int(l) & 255
    gi0 = PERM[1 + I + PERM[1 + J + PERM[1 + K + PERM[1 + L]]]] & 0x1f
    gi1 = PERM[1 + I + i1 + PERM[1 + J + j1 + PERM[1 + K + k1 + PERM[1 + L + l1]]]] & 0x1f
    gi2 = PERM[1 + I + i2 + PERM[1 + J + j2 + PERM[1 + K + k2 + PERM[1 + L + l2]]]] & 0x1f
    gi3 = PERM[1 + I + i3 + PERM[1 + J + j3 + PERM[1 + K + k3 + PERM[1 + L + l3]]]] & 0x1f
    gi4 = PERM[1 + I + 1 + PERM[1 + J + 1 + PERM[1 + K + 1 + PERM[1 + L + 1]]]] & 0x1f

    t0 = 0.6 - x0*x0 - y0*y0 - z0*z0 - w0*w0
    noise = zeros(5)
    if t0 >= 0.0
        t0 *= t0
        noise[1] = t0 * t0 * dot4(GRAD4[gi0 + 1], x0, y0, z0, w0)
    end
    t1 = 0.6 - x1*x1 - y1*y1 - z1*z1 - w1*w1
    if t1 >= 0.0
        t1 *= t1
        noise[2]= t1 * t1 * dot4(GRAD4[gi1 + 1], x1, y1, z1, w1)
    end
    t2 = 0.6 - x2*x2 - y2*y2 - z2*z2 - w2*w2
    if t2 >= 0.0
        t2 *= t2
        noise[3] = t2 * t2 * dot4(GRAD4[gi2 + 1], x2, y2, z2, w2)
    end
    t3 = 0.6 - x3*x3 - y3*y3 - z3*z3 - w3*w3
    if t3 >= 0.0
        t3 *= t3
        noise[4] = t3 * t3 * dot4(GRAD4[gi3 + 1], x3, y3, z3, w3)
    end
    t4 = 0.6 - x4*x4 - y4*y4 - z4*z4 - w4*w4
    if t4 >= 0.0
        t4 *= t4
        noise[5] = t4 * t4 * dot4(GRAD4[gi4 + 1], x4, y4, z4, w4)
    end

    return 27.0 * sum(noise)
end

function noise4(x, y, z, w, octaves, persistence = 0.5, lacunarity = 2)
    freq = 1.0
    amp = 1.0
    max = 1.0
    total = noise4(x, y, z, w)
    for i = 1:(octaves-1)
        freq *= lacunarity
        amp *= persistence
        max += amp
        total += noise4(x * freq, y * freq, z * freq, w * freq) * amp
    end
    return total / max
end
