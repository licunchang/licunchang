

http://stackoverflow.com/questions/807506/threads-vs-processes-in-linux

I've recently heard a few people say that in Linux, it is almost always better to use processes instead of threads, since Linux is very efficient in handling processes, and because there are so many problems (such as locking) associated with threads. However, I am suspicious, because it seems like threads could give a pretty big performance gain in some situations.

So my question is, when faced with a situation that threads and processes could both handle pretty well, should I use processes or threads? For example, if I were writing a web server, should I use processes or threads (or a combination)?

听很多人都说，在 linux 中，大多数情况下，进程的使用都要好于现成的使用，因为 linux 在处理进程方面非常的高效，并且在处理线程的时候有许多的问题（比如说锁的问题）。然而，我却怀疑，现成在很多情境下应该有更好的性能表现。

所以为题就是，当我们遇到一个使用进程和线程都可以的情况下，我们应该使用进程还是线程来处理。例如，如果我写了一个 web 服务器，那么我应该使用线程还是进程来处理。

Linux uses a 1-1 threading model, with (to the kernel) no distinction between processes and threads -- everything is simply a runnable task. *

On Linux, the system call clone clones a task, with a configurable level of sharing, among which are:

CLONE_FILES: share the same file descriptor table (instead of creating a copy)
CLONE_PARENT: don't set up a parent-child relationship between the new task and the old (otherwise, child's getppid() = parent's getpid())
CLONE_VM: share the same memory space (instead of creating a COW copy)
fork() calls clone(least sharing) and pthread_create() calls clone(most sharing). **

forking costs a tiny bit more than pthread_createing because of copying tables and creating COW mappings for memory, but the Linux kernel developers have tried (and succeeded) at minimizing those costs.

Switching between tasks, if they share the same memory space and various tables, will be a tiny bit cheaper than if they aren't shared, because the data may already be loaded in cache. However, switching tasks is still very fast even if nothing is shared -- this is something else that Linux kernel developers try to ensure (and succeed at ensuring).

In fact, if you are on a multi-processor system, not sharing may actually be beneficial to performance: if each task is running on a different processor, synchronizing shared memory is expensive.

Linux 使用1比1的线程模型，对于内核来说，线程和进程之间是没有区别的，他们简单的抽象成一个可以运行的任务。

在 linux 中，系统调用 `clone` 克隆一个任务，


`forking` 比 `pthread_createing` 耗用多一些的资源，因为拷贝表并建立内存映射，但是 linux 的内核开发者正在师徒最小化这些代价。

在任务之间切换，如果他们共享相同的内存空间和很多表，这样将比不共享内存空间和表花费少一些，因为数据可能早就已经加载到缓存中去了，然而，即使是不共享任何东西，任务之间切换依然是很高效的，这需要linux的内核开发者确认这一点。

事实上，如果是一个多进程系统，不共享可能对性能的表现有益处，如果每一个任务在不同的进程中运行，同步共享内存将是昂贵的。

That depends on a lot of factors. Processes are more heavy-weight than threads, and have a higher startup and shutdown cost. Interprocess communication (IPC) is also harder and slower than interthread communication.

Conversely, processes are safer and more secure than threads, because each process runs in its own virtual address space. If one process crashes or has a buffer overrun, it does not affect any other process at all, whereas if a thread crashes, it takes down all of the other threads in the process, and if a thread has a buffer overrun, it opens up a security hole in all of the threads.

So, if your application's modules can run mostly independently with little communication, you should probably use processes if you can afford the startup and shutdown costs. The performance hit of IPC will be minimal, and you'll be slightly safer against bugs and security holes. If you need every bit of performance you can get or have a lot of shared data (such as complex data structures), go with threads.

这取决与很多因素，进程要比线程重量级。并且有一个更高的停启代价，进程间通信也比县城建通讯要难一些并且要慢一些。

进程一般来说要比线程要安全一些，因为每一个线程都运行在自己的虚拟地址空间。如果一个进程崩溃了或者有内存溢出，他不会影响其他的进程，但是如果一个现成崩溃之后，他会影响到进程中的其他的线程，并且一个线程有一个内存溢出，