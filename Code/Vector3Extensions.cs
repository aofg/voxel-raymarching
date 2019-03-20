/*
 * Copyright (C) 2019 Aler Denisov <aler@aofg.cc>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


using UnityEngine;

namespace VoxelRaymarching
{
    public static class Vector3Extensions {
        public static Vector3 mul(this Vector3 a, Vector3 b)
        {
            return new Vector3(
                a.x * b.x,
                a.y * b.y,
                a.z * b.z
            );
        }

        public static Vector3 xxx(this Vector3 a)
        {
            return new Vector3(a.x, a.x, a.x);
        }

        public static Vector3 xxy(this Vector3 a)
        {
            return new Vector3(a.x, a.x, a.y);
        }

        public static Vector3 xxz(this Vector3 a)
        {
            return new Vector3(a.x, a.x, a.z);
        }

        public static Vector3 xyx(this Vector3 a)
        {
            return new Vector3(a.x, a.y, a.x);
        }

        public static Vector3 xyy(this Vector3 a)
        {
            return new Vector3(a.x, a.y, a.y);
        }

        public static Vector3 xyz(this Vector3 a)
        {
            return new Vector3(a.x, a.y, a.z);
        }

        public static Vector3 xzx(this Vector3 a)
        {
            return new Vector3(a.x, a.z, a.x);
        }

        public static Vector3 xzy(this Vector3 a)
        {
            return new Vector3(a.x, a.z, a.y);
        }

        public static Vector3 xzz(this Vector3 a)
        {
            return new Vector3(a.x, a.z, a.z);
        }

        public static Vector3 yxx(this Vector3 a)
        {
            return new Vector3(a.y, a.x, a.x);
        }

        public static Vector3 yxy(this Vector3 a)
        {
            return new Vector3(a.y, a.x, a.y);
        }

        public static Vector3 yxz(this Vector3 a)
        {
            return new Vector3(a.y, a.x, a.z);
        }

        public static Vector3 yyx(this Vector3 a)
        {
            return new Vector3(a.y, a.y, a.x);
        }

        public static Vector3 yyy(this Vector3 a)
        {
            return new Vector3(a.y, a.y, a.y);
        }

        public static Vector3 yyz(this Vector3 a)
        {
            return new Vector3(a.y, a.y, a.z);
        }

        public static Vector3 yzx(this Vector3 a)
        {
            return new Vector3(a.y, a.z, a.x);
        }

        public static Vector3 yzy(this Vector3 a)
        {
            return new Vector3(a.y, a.z, a.y);
        }

        public static Vector3 yzz(this Vector3 a)
        {
            return new Vector3(a.y, a.z, a.z);
        }

        public static Vector3 zxx(this Vector3 a)
        {
            return new Vector3(a.z, a.x, a.x);
        }

        public static Vector3 zxy(this Vector3 a)
        {
            return new Vector3(a.z, a.x, a.y);
        }

        public static Vector3 zxz(this Vector3 a)
        {
            return new Vector3(a.z, a.x, a.z);
        }

        public static Vector3 zyx(this Vector3 a)
        {
            return new Vector3(a.z, a.y, a.x);
        }

        public static Vector3 zyy(this Vector3 a)
        {
            return new Vector3(a.z, a.y, a.y);
        }

        public static Vector3 zyz(this Vector3 a)
        {
            return new Vector3(a.z, a.y, a.z);
        }

        public static Vector3 zzx(this Vector3 a)
        {
            return new Vector3(a.z, a.z, a.x);
        }

        public static Vector3 zzy(this Vector3 a)
        {
            return new Vector3(a.z, a.z, a.y);
        }

        public static Vector3 zzz(this Vector3 a)
        {
            return new Vector3(a.z, a.z, a.z);
        }

        public static Vector2 xx(this Vector3 a)
        {
            return new Vector2(a.x, a.x);
        }

        public static Vector2 xy(this Vector3 a)
        {
            return new Vector2(a.x, a.y);
        }

        public static Vector2 xz(this Vector3 a)
        {
            return new Vector2(a.x, a.z);
        }

        public static Vector2 yx(this Vector3 a)
        {
            return new Vector2(a.y, a.x);
        }

        public static Vector2 yy(this Vector3 a)
        {
            return new Vector2(a.y, a.y);
        }

        public static Vector2 yz(this Vector3 a)
        {
            return new Vector2(a.y, a.z);
        }

        public static Vector2 zx(this Vector3 a)
        {
            return new Vector2(a.z, a.x);
        }

        public static Vector2 zy(this Vector3 a)
        {
            return new Vector2(a.z, a.y);
        }

        public static Vector2 zz(this Vector3 a)
        {
            return new Vector2(a.z, a.z);
        }
    }
    
}