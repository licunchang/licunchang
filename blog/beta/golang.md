**File Name** golang.md  

**Description**  golang     
**Author** licunchang  
**Version** 1.0.20131217  

------

## 安装

    rm -R -f /usr/local/go

    tar -C /usr/local -xzf /usr/local/src/go1.2.linux-amd64.tar.gz

    cat >> /etc/profile.d/go.sh <<'EOF'
    export GOROOT=/usr/local/go
    export PATH=$PATH:$GOROOT/bin
    EOF

    source /etc/profile

## 测试安装是否成功

    cd ~
    cat >> hello.go <<'EOF'
    package main

    import "fmt"

    func main() {
        fmt.Printf("hello, world\n")
    }
    EOF

    go run hello.go

## 设置环境变量

    mkdir -p $HOME/go/{pkg,bin,src}
    
    cat >> $HOME/.profile <<'EOF'
    GOPATH=$HOME/go
    PATH=$PATH:$GOPATH/bin
    export GOPATH PATH
    EOF

    source $HOME/.profile

**Note that `GOPATH` must not be the same path as your `GOROOT`.**


------

    bin/
        streak                         # command executable
        todo                           # command executable
    pkg/
        linux_amd64/
            code.google.com/p/goauth2/
                oauth.a                # package object
            github.com/nf/todo/
                task.a                 # package object
    src/
        code.google.com/p/goauth2/
            .hg/                       # mercurial repository metadata
            oauth/
                oauth.go               # package source
                oauth_test.go          # test source
        github.com/nf/
            streak/
                .git/                  # git repository metadata
                oauth.go               # command source
                streak.go              # command source
            todo/
                .git/                  # git repository metadata
                task/
                    task.go            # package source
                todo.go                # command source

------

    licunchang@licunchang-virtual-machine:~$ go env
    GOARCH="amd64"
    GOBIN=""
    GOCHAR="6"
    GOEXE=""
    GOHOSTARCH="amd64"
    GOHOSTOS="linux"
    GOOS="linux"
    GOPATH="/home/licunchang/go"
    GORACE=""
    GOROOT="/usr/local/go"
    GOTOOLDIR="/usr/local/go/pkg/tool/linux_amd64"
    CC="gcc"
    GOGCCFLAGS="-g -O2 -fPIC -m64 -pthread"
    CGO_ENABLED="1"

### Test your installation

    vi $HOME/go/src/github.com/licunchang/hello/hello.go

    package main

    import "fmt"

    func main() {
        fmt.Printf("hello, world\n")
    }

install

    $ go install github.com/licunchang/hello

or

    $ cd $GOPATH/src/github.com/user/hello
    $ go install

    $ $GOPATH/bin/hello
    Hello, world.

### Your first library

    mkdir -p $GOPATH/src/github.com/licunchang/newmath

    vi $GOPATH/src/github.com/licunchang/newmath/sqrt.go

    // Package newmath is a trivial example package.
    package newmath

    // Sqrt returns an approximation to the square root of x.
    func Sqrt(x float64) float64 {
        z := 0.0
        for i := 0; i < 1000; i++ {
            z -= (z*z - x) / (2 * x)
        }
        return z
    }

    $ go build github.com/licunchang/newmath
    $ go install github.com/licunchang/newmath

    vi $GOPATH/src/github.com/licunchang/hello/hello.go

    package main

    import (
        "fmt"
        "github.com/licunchang/newmath"
    )

    func main() {
        fmt.Printf("Hello, world.  Sqrt(2) = %v\n", newmath.Sqrt(2))
    }

    $ go install github.com/licunchang/hello

    licunchang@licunchang-virtual-machine:~$ tree go/
    go/
    ├── bin
    │   └── hello
    ├── pkg
    │   └── linux_amd64
    │       └── github.com
    │           └── licunchang
    │               └── newmath.a
    └── src
        └── github.com
            └── licunchang
                ├── hello
                │   └── hello.go
                └── newmath
                    └── sqrt.go

    10 directories, 4 files

## Package names

Go's convention is that the package name is the last element of the import path: the package imported as "crypto/rot13" should be named rot13.

Executable commands must always use package main.

There is no requirement that package names be unique across all packages linked into a single binary, only that the import paths (their full file names) be unique.

### Testing

    vi $GOPATH/src/github.com/licunchang/newmath/sqrt_test.go

    package newmath

    import "testing"

    func TestSqrt(t *testing.T) {
        const in, out = 4, 2
        if x := Sqrt(in); x != out {
            t.Errorf("Sqrt(%v) = %v, want %v", in, x, out)
        }
    }

    go test github.com/licunchang/newmath





`package <pkgName>`（在我们的例子中是`package main`）这一行告诉我们当前文件属于哪个包，而包名`main`则告诉我们它是一个可独立运行的包，它在编译后会产生可执行文件。除了`main`包之外，其它的包最后都会生成`*.a`文件（也就是包文件）并放置在`$GOPATH/pkg/$GOOS_$GOARCH`中（以Mac为例就是`$GOPATH/pkg/darwin_amd64`）。

>每一个可独立运行的Go程序，必定包含一个`package main`，在这个`main`包中必定包含一个入口函数`main`，而这个函数既没有参数，也没有返回值。

使用`var`关键字是Go最基本的定义变量方式，与C语言不同的是Go把变量类型放在变量名后面：

    //定义一个名称为“variableName”，类型为"type"的变量
    var variableName type

定义多个变量

    //定义三个类型都是“type”的三个变量
    var vname1, vname2, vname3 type

    /*
        定义三个变量，它们分别初始化相应的值
        vname1为v1，vname2为v2，vname3为v3
        编译器会根据初始化的值自动推导出相应的类型
    */
    vname1, vname2, vname3 := v1, v2, v3

现在是不是看上去非常简洁了？`:=`这个符号直接取代了`var`和`type`,这种形式叫做简短声明。不过它有一个限制，那就是它只能用在函数内部；在函数外部使用则会无法编译通过，所以**一般用`var`方式来定义全局变量**。

`_`（下划线）是个特殊的变量名，任何赋予它的值都会被丢弃。在这个例子中，我们将值`35`赋予`b`，并同时丢弃`34`：

    _, b := 34, 35

所谓常量，也就是在程序编译阶段就确定下来的值，而程序在运行时则无法改变该值。在Go程序中，常量可定义为数值、布尔值或字符串等类型。

它的语法如下：

    const constantName = value
    //如果需要，也可以明确指定常量的类型：
    const Pi float32 = 3.1415926

下面是一些常量声明的例子：

    const Pi = 3.1415926
    const i = 10000
    const MaxThread = 10
    const prefix = "astaxie_"

整数类型有无符号和带符号两种。Go同时支持`int`和`uint`，这两种类型的长度相同，但具体长度取决于不同编译器的实现。~~当前的gcc和gccgo编译器在32位和64位平台上都使用32位来表示`int`和`uint`，但未来在64位平台上可能增加到64位~~。Go里面也有直接定义好位数的类型：`rune`, `int8`, `int16`, `int32`, `int64`和`byte`, `uint8`, `uint16`, `uint32`, `uint64`。其中`rune`是`int32`的别称，`byte`是`uint8`的别称。

>需要注意的一点是，这些类型的变量之间不允许互相赋值或操作，不然会在编译时引起编译器报错。
>
>如下的代码会产生错误
>
>>  var a int8

>>  var b int32

>>  c:=a + b
>
>另外，尽管int的长度是32 bit, 但int 与 int32并不可以互用。

浮点数的类型有`float32`和`float64`两种（没有`float`类型），默认是`float64`。

Go中的字符串都是采用`UTF-8`字符集编码。字符串是用一对双引号（`""`）或反引号（`` ` `` `` ` ``）括起来定义，它的类型是`string`。

    //示例代码
    var frenchHello string  // 声明变量为字符串的一般方法
    var emptyString string = ""  // 声明了一个字符串变量，初始化为空字符串
    func test() {
        no, yes, maybe := "no", "yes", "maybe"  // 简短声明，同时声明多个变量
        japaneseHello := "Ohaiou"  // 同上
        frenchHello = "Bonjour"  // 常规赋值
    }

在Go中字符串是不可变的，例如下面的代码编译时会报错：

    var s string = "hello"
    s[0] = 'c'

数组不能改变长度。




