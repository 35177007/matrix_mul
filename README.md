# 汇编语言程序设计 矩阵乘法
使用```x86```汇编，```Visual Studio 2017```开发，参考了《汇编语言 基于x86处理器》<br>
程序使用了作者提供的库，请确保**安装并配置好**该书提供的```Irvine32```外部链接库

## 1. 使用教程
[配置```Visual Studio 2017```](https://www.cnblogs.com/heben/p/7653067.html)<br>
[配置```Irvine32```链接库](https://www.jianshu.com/p/c34bae963a87)
## 2. 输入数据要求
1. 分别从两个文件读入矩阵 A 和 B，数据类型仅为**整型**，单个矩阵元素数不超过**20**.
2. 矩阵每一行以**回车**结尾，**最后一行**也应如此。
3. A 和 B 应满足矩阵乘法的条件；否则程序会捕获异常并输出异常信息。
### 2.1 矩阵 A 示例
  ```
  // a.txt 
  2 3 13 34
  4 23 44 111
  1 2 3 4
    
  ```
### 2.2 矩阵 B 示例
  ```
  // b.txt
  1 2 3 
  5 6 7 
  9 10 11
  12 13 14
  
  ```
