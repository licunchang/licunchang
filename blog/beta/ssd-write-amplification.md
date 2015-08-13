**File Name** ssd-write-amplification.md  

**Description**  SSD 的写入方法  
**Author** licunchang  
**Version** 1.0.20130908  

------

写入放大(Write amplification)是闪存和固态硬盘的一个特有的不让人喜欢的现象，因为闪存在写入数据之前必须擦除(erase)，在这个过程中，用户数据和元数据可能要被移动或者重写不止一次，所以导致实际物理上写入的数据量可能是逻辑写入量的数倍。这些额外增加的写入需求减少了元件的寿命，并且还侵占了更多的带宽从而影响到了随机读写能力。写入放大有一个公式

![Simple write amplification formula](images/ssd-write-amplification.md/wa.png "Simple write amplification formula")

写入放大率等于闪存实际写入的数据量除以系统要写入的数据量，这个值在不压缩数据的情况下，是不可能小于 1 的，压缩数据的情况下，最优情况下可以达到0.14甚至更小。

闪存

基于闪存操作的特性，数据不能像存储到机械硬盘那样直接写入。当数据第一次写到 SSD 的时候，因为所有闪存颗粒都是处于已经擦除的状态，所以数据可以直接以页为单位(页大小通常是4~8KB)写入。SSD的主控制器维护着一个逻辑到物理存储的映射关系

![NAND Flash memory writes data in 4 KB pages and erases data in 256 KB blocks](images/ssd-write-amplification.md/NAND_Flash_Pages_and_Blocks.png "NAND Flash memory writes data in 4 KB pages and erases data in 256 KB blocks")



http://www.pceva.com.cn/topic/crucialssd/index-6_2.html
http://en.wikipedia.org/wiki/Write_amplification
