//
//  decompressIcon.m
//  coderesign
//
//  Created by MiaoGuangfa on 9/15/15.
//  Copyright (c) 2015 MiaoGuangfa. All rights reserved.
//

#import "decompressIcon.h"
#include <Python/Python.h>

@implementation decompressIcon

+ (void)convertEncryptedImageDataToNormal:(NSString *)encryptedImagePath withNewFilePath:(NSString *)newFilePath withPy:(NSString *)pythonPath
{
    if (encryptedImagePath == NULL || encryptedImagePath.length == 0 ||
        newFilePath == NULL || newFilePath.length == 0 ||
        pythonPath == NULL || pythonPath.length == 0) {
        return;
    }
    
    Py_Initialize();
    
    if ( !Py_IsInitialized() )
    {
        return;
    }
    
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
    
    pFunc = PyDict_GetItemString(pDict, "updatePNG");
    if ( !pFunc || !PyCallable_Check(pFunc) )
    {
        printf("can't find function [add]");
        getchar();
        return;
    }
    
    pArgs = PyTuple_Pack(2, PyString_FromString([encryptedImagePath cStringUsingEncoding:NSUTF8StringEncoding]), PyString_FromString([newFilePath cStringUsingEncoding:NSUTF8StringEncoding]));
    PyObject_CallObject(pFunc, pArgs);
    
    Py_DECREF(pName);
    Py_DECREF(pArgs); 
    Py_DECREF(pModule);

    Py_Finalize();
}
@end
