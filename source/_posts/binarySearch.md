---
title: 二分查找
date: 2018/10/9 15:52:00
tags: [武汉,算法]
categories: document
photo: https://s2.ax1x.com/2019/02/21/kRgxPO.png
---

<center>_即使最简单的算法也有很多的细节_</center>
<!-- more -->

### 简介
**二分查找** 也称折半查找（Binary Search），它是一种效率较高的查找方法。但是，折半查找要求线性表必须采用顺序存储结构，而且表中元素按关键字 **有序排列**。

### 基本思想
假设R[low...high]是当前的查找区间，key为需要查找的值。    
1、先确定该区间的中间位置：**mid = （low+high）/2**。    
2、将key值域R[mid]比较：若相等，则查找成功并返回此位置，否则进一步确定新的查找区间:  
&emsp;&emsp;a、若R[mid]>key，则可知，如果表中存在关键字等于key的结点，则该结点位置一定位于mid的左边的子表R[1...mid-1]中。
&emsp;&emsp;a、若R[mid]<key，则可知，如果表中存在关键字等于key的结点，则该结点位置一定位于mid的右边的子表R[mid+1...high]中。    
3、每经过一次查找，查找区间就会减半，重复这一过程直到找到关键字为key的结点，或缩减至查找子区间右侧小于左侧，则区间不存在，查找失败，按照一般约定，没有找到目标元素，则把应该插入目标元素的位置返回。

### 代码
#### 循环实现
```java
    public static int binarySearch(int[] arr, int key) {
            int low = 0;
            int high = arr.length - 1;
            int mid;

            while (low <= high) {
                //不要用（low+high）/2,可能溢出。规范：low + (high - low) / 2;
                mid = low + (high - low) / 2;
                if (arr[mid] < key) {
                    low = mid + 1;
                } else if (arr[mid] > key) {
                    high = mid - 1;
                } else {
                    return mid;
                }
            }
            //没有找到目标元素，则把应该插入的位置返回
            return low;
        }
```

#### 递归实现
```java
    public static int binarySearchRecur(int[] arr, int key, int low, int high) {
        if (low > high) return low;
        int mid = low + (high - low) / 2;
        if (arr[mid] < key) {
            return binarySearchRecur(arr, key, mid + 1, high);
        } else if (arr[mid] > key) {
            return binarySearchRecur(arr, key, low, mid - 1);
        } else {
            return low;
        }
    }
```

需要注意的是获取mid值得时候不要直接使用：**mid = （low+high）/2**，因为当 **low+high>Integer.Max** 的时候会溢出，所以要用 **mid = low + (high - low) / 2** 来获取mid的值。

#### 包含重复元素数组
上面两个方法只能处理不包含重复数据的数组，否则返回结果会不准确     
例：当时组为 int a[] = {1, 2, 3, 4, 5, 7, 7, 9, 10} 时    
第一次查找区间缩减为{7, 7, 9, 10}, low=5，high=8，此时mid=6，a[6]=7, 查找成功返回结点位置6，但数组a中第一次出现7的位置应该是a[5],而不是a[6];
```java
    public static int firstOccurrence(int[] arr, int key) {
        int low = 0;
        int high = arr.length - 1;
        int mid;

        while (low <= high) {
            mid = low + (high - low) / 2;
            if (arr[mid] < key) {
                low = mid + 1;
            } else if (arr[mid] >= key) {
                high = mid - 1;
            }
        }
        return low;
    }

    public static int firstOccurrenceRecur(int[] arr, int key, int low, int high) {
        if (low > high) return low;
        int mid = low + (high - low) / 2;
        if (arr[mid] < key) {
            return binarySearchRecur(arr, key, mid + 1, high);
        } else {
            return binarySearchRecur(arr, key, low, mid - 1);
        }
    }
```

通过与上面代码比较发现仅仅是修改判定条件 **arr[mid] > key** 为 **arr[mid] >= key**，这样当arr[mid] = key时，会继续执行循环体，而不是直接返回查找到的位置，在这次循环中，主要是判断arr[mid-1]是否等于key，如果相等则第一次出现关键字为key的结点的位置就会前移一位。high不断向low逼近，直到high<low，此时循环结束，返回第一次出现关键字为key的结点位置。

### 总结
#### 优缺点
二分查找的时间复杂度为O(logn)，远远好于顺序查找的O(n)。但是使用二分查找前，必须将表按关键字排序，而排序本身是一种比较费时的运算，即使采用高效的排序方法也要花费O(nlogn)的时间。

#### 适用场景
根据二分查找的优缺点我们可以想到，二分查找特别适用于那种一经建立就很少改动，而又经常需要查找的线性表。
