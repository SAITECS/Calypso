/**
 * Basic tests for Calypso.
 *
 * Build with:
 *   $ clang++ -std=c++11 -c showcase.cpp -o showcase.cpp.o
 *   $ ar rcs libshowcase.a showcase.cpp.o
 *   $ ldc2 -cpp-args -std=c++11 -Llibshowcase.a -L-lstdc++ showcase.d
 */

modmap (C++) "showcase.hpp";
    // « modmap » is a new keyword introduced to specify the C++ headers.
    // It doesn't import anything, its only role is to tell Clang which C++ headers this module depends upon.
    //
    // Currently Calypso makes Clang gathers all the headers togehter into one precompiled header, which is
    // then lazily loaded by the import (C++) directives.

import std.stdio, std.conv, std.string;
import (C++) test._; // « _ » is a special module that contains all the global variables, global functions
                // and typedefs of a namespace (the ones which aren't nested inside a struct or a class,
                // or another namespace).
import (C++) test.testStruct; // imports test::testStruct
import (C++) test.testClass; // imports test::testClass
import (C++) test.testInherit; // etc. each struct/class/enum template or not is placed in a module named after it
import (C++) test.anotherClass;
import (C++) test.testMultipleInherit;
import (C++) test.enumTest;
import (C++) test.arrayOfTen;
import (C++) test.tempWithPartialSpecs; // imports the primary class template as well as all its partial and explicit specializations

// NOTE: The imports (C++) only take the AST into consideration, the header file where the symbols are
//       declared doesn't matter as long as they are in the precompiled header.

class testDClass
{
public:
    testStruct mycstruct;
    int test;

    this()
    {
        test = 78;
        mycstruct.f = 6.12;
        mycstruct.c = 'p';
    }
}

// D class inheriting from a C++ class, incl. methods overriding virtual C++ methods
// Calypso generates a new C++ vtable with thunk functions that makes them callable from C++ through the base method.
//
// The resulting "hybrid" class holds pointers to the 2 different kinds of vtable, the D one and the C++ one(s).
class DCXXclass : testMultipleInherit
{
public:
    uint someUint = 9;

    override const (char *) hello(bool ceres)
    {
        if (ceres && someUint > 5)
            return "Hello Ceres";

        return "Hello Pluto";
    }

    // Typical thunk function generated by dcxxclasses.cpp
//     static bool thunkTest(testMultipleInherit cppthis, bool who)
//     {
//        void* __tmp1723 = cast(void*) cppthis;
//         __tmp1723 += -(void*).sizeof * 2;
//         return (cast(DCXXclass)__tmp1723).hello(who);
//     }
}

void main()
{
    std.stdio.writeln("[Simple C++ function call test]");
    writeln("testFunc('a') = ", testFunc('a'));
    writeln("testFunc('b') = ", testFunc('b'));
    writeln("testFunc('c') = ", testFunc('c'));

    // Global variables
    std.stdio.writeln("\n[Global variables]");
    writeln("testDoubleVar = ", testDoubleVar);

    writeln("testVar.f = ", testVar.f);
    writeln("testVar.c = ", testVar.c);
    writeln("testVar.n = ", testVar.n);

    // Structs
    std.stdio.writeln("\n[Structs]");
    testStruct cs;
    cs.f = 1.56;
    cs.c = 'x';
    writeln("cs.f = ", cs.f);
    writeln("cs.c = ", cs.c);

    // D class with a C struct member
    std.stdio.writeln("\n[D class with a C struct member]");
    auto dd = new testDClass;
    dd.mycstruct.f = 9.51;
    dd.mycstruct.c = 'o';
    writeln("dd.mycstruct.f = ", dd.mycstruct.f);

    // Classes: multiple inheritance, static downcasts
    std.stdio.writeln("\n[Classes: multiple inheritance, static downcasts]");
    testClass *cls = new testInherit;
    cls.priv.f = 5.25;
    writeln("cls.priv.f = ", cls.priv.f);
    writeln("cls.echo(9, 8) = ", cls.echo(9, 8)); // 42 * 5 == 210 expected if the ctor was called
    writeln("cls.echo2(2.5) = ", cls.echo2(2.5));

    auto mul = new testMultipleInherit;
    mul.pointerToStruct = &cs;
    writeln("mul.pointerToStruct = ", mul.pointerToStruct);
    writeln("mul.hello(false) = ", to!string(mul.hello(false)));

    anotherClass* ano = new testMultipleInherit;
    writeln("ano.hello(true) = ", to!string(ano.hello(true)));

    // Hybrid D-C++ classes
    std.stdio.writeln("\n[Hybrid D-C++ classes]");
    auto isThisRealLife = new DCXXclass;
    isThisRealLife.someUint = 187;
    writeln("isThisRealLife.someUint = ", isThisRealLife.someUint);
    isThisRealLife.pointerToStruct = &cs;
    writeln("isThisRealLife.pointerToStruct = ", isThisRealLife.pointerToStruct);
    writeln("isThisRealLife.hello(true) = ", to!string(isThisRealLife.hello(true)));

    // Downcasting to the C++ base class to check the C++ vtable generated by Calypso
    std.stdio.writeln("\n[Downcasting to the C++ base class, checking the C++ vtable generated by Calypso]");
    testMultipleInherit* testCast = isThisRealLife;
    writeln("testCast.hello(true) = ", to!string(testCast.hello(true)));
    writeln("testCast.echo2() = ", testCast.echo2(3));

    // Enums
    std.stdio.writeln("\n[Enums]");
    enumTest someEnumValue = enumTest.ENUM_SOMEVAL;
    writeln("someEnumValue = ", someEnumValue);

    // Class templates and arrays
    std.stdio.writeln("\n[Class templates and arrays]");
    auto amIAValue = new arrayOfTen!char;
    amIAValue.someArray[4] = 'h';
    writeln("amIAValue.FifthChar() = ", amIAValue.FifthChar());

    // Partial and explicit class template specializations
    std.stdio.writeln("\n[Partial and explicit class template specializations]");
    auto t1 = new tempWithPartialSpecs!(double, 10);
    auto t2 = new tempWithPartialSpecs!(char, 8);
    auto t3 = new tempWithPartialSpecs!(bool, 5);
    writeln("t1 instantied from ", to!string(t1.toChars));
    writeln("t2 instantied from ", to!string(t2.toChars));
    writeln("t3 instantied from ", to!string(t3.toChars));

    // Function templates
    std.stdio.writeln("\n[Function templates]");
    char _char;
    short _short;
    double _double;
    testStruct _testStruct;
    writeln("funcTempSizeOf(_char) = ", funcTempSizeOf(_char));
    writeln("funcTempSizeOf(_short) = ", funcTempSizeOf(_short));
    writeln("funcTempSizeOf(_double) = ", funcTempSizeOf(_double));
//     writeln("funcTempSizeOf(_testStruct) = ", funcTempSizeOf(_testStruct));

    // ======== ========
    // And finally... just checking if basic D functionality still works as usual i.e if everything else wasn't broken by inadvertance

    void DFunc(int o) { writeln(""); }

    class DInherit : testDClass
    {
    public:
        float floatArray[5];
    }

    DFunc(5);
    auto pureDClass = new DInherit;
}
