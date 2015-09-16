//
//  coderesignTools.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/15/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "coderesignTools.h"
#include <Python/Python.h>

@implementation coderesignTools

+ (void)convertEncryptedImageDataToNormal:(NSString *)encryptedImageData withNewFilePath:(NSString *)newFilePath withPy:(NSString *)pythonPath
{
    
    NSData *_icon_data = [[NSFileManager defaultManager]contentsAtPath:encryptedImageData];
    
    
    if (encryptedImageData == NULL || newFilePath == NULL) {
        return;
    }
    
    
    Py_Initialize();
    
    // 检查初始化是否成功
    if ( !Py_IsInitialized() )
    {
        return;
    }
    
    // 添加当前路径
    //把输入的字符串作为Python代码直接运行，返回0
    //表示成功，-1表示有错。大多时候错误都是因为字符串
    //中有语法错误。
    
    NSArray *_pythonPaths = [pythonPath componentsSeparatedByString:@"/"];
    NSString *workpath;
    if (_pythonPaths != nil) {
        NSString *python = _pythonPaths[_pythonPaths.count -1];
        NSUInteger leng = python.length;
        workpath = [pythonPath substringToIndex:(pythonPath.length - leng)];
    }
    
    NSString *newworkpath = [@"sys.path.append('" stringByAppendingFormat:@"%@')", workpath];
    const char * cworkpath = [newworkpath cStringUsingEncoding:NSUTF8StringEncoding];
    
    PyRun_SimpleString("import sys");
    
    PyRun_SimpleString(cworkpath);
    PyRun_SimpleString("from struct import *");
    PyRun_SimpleString("from zlib import *");
    PyRun_SimpleString("import stat");
    PyRun_SimpleString("import sys");
    PyRun_SimpleString("import os");
    
    PyObject *pName,*pModule,*pDict,*pFunc,*pArgs;
    
    // 载入名为pytest的脚本
    pName = PyString_FromString("iconDecompress");
    pModule = PyImport_Import(pName);
    if ( !pModule )
    {
        printf("can't find iconDecompress.py");
        getchar();
        return;
    }
    pDict = PyModule_GetDict(pModule);
    if ( !pDict )
    {
        return;
    }
    
    // 找出函数名为add的函数
    pFunc = PyDict_GetItemString(pDict, "updatePNG");
    if ( !pFunc || !PyCallable_Check(pFunc) )
    {
        printf("can't find function [add]");
        getchar();
        return;
    }
    
    // 参数进栈
    //PyObject *pArgs;
    //pArgs = PyTuple_New(2);
    
    //  PyObject* Py_BuildValue(char *format, ...)
    //  把C++的变量转换成一个Python对象。当需要从
    //  C++传递变量到Python时，就会使用这个函数。此函数
    //  有点类似C的printf，但格式不同。常用的格式有
    //  s 表示字符串，
    //  i 表示整型变量，
    //  f 表示浮点数，
    //  O 表示一个Python对象。
//    NSLog(@"arg1: %@, arg2: %@", encryptedImageData, newFilePath);
//    PyTuple_SetItem(pArgs, 0, Py_BuildValue("s",encryptedImageData));
//    PyTuple_SetItem(pArgs, 1, Py_BuildValue("s",newFilePath));
    pArgs = PyTuple_Pack(2, PyString_FromString([encryptedImageData cStringUsingEncoding:NSUTF8StringEncoding]), PyString_FromString([newFilePath cStringUsingEncoding:NSUTF8StringEncoding]));
    // 调用Python函数
    PyObject_CallObject(pFunc, pArgs);
    
    
    Py_DECREF(pName);
    Py_DECREF(pArgs); 
    Py_DECREF(pModule);
    
//    PyObject *py_main, *py_dict;
//    py_main = PyImport_AddModule("__main__");
//    py_dict = PyModule_GetDict(py_main);
//    PyObject * PyRes = PyRun_String("print this is python shell", Py_single_input, py_dict, py_dict);
//    
//    
//    
//    PyRun_SimpleString("import sys");
//    PyRun_SimpleString("sys.path.append('./')");
//    
//    PyObject *pModule = NULL;
//    PyObject *pFunc = NULL;
//    PyObject *argList;
//    NSLog(@"therad %d", [NSThread isMainThread]);
//   // NSString *_path = [[NSBundle bundleForClass: [self class]] pathForResource:@"teicon" ofType:@"png"];
//    
//    pModule = PyImport_ImportModule([pythonPath cStringUsingEncoding:NSUTF8StringEncoding]);
//    pFunc = PyObject_GetAttrString(pModule, "updatePNG");
//    argList = Py_BuildValue("(1)", encryptedImageData);
//    argList = Py_BuildValue("(2)", [newFilePath cStringUsingEncoding:NSUTF8StringEncoding]);
//    PyEval_CallObject(pModule, argList);
    
    
    Py_Finalize();
}
@end
