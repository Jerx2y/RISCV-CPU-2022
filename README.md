# <img src="/README.assets/cpu.png" width="40" align=center /> RISCV-CPU 2022

> [Project Introduction](https://github.com/ACMClassCourses/RISCV-CPU)

## Designment

![design](/README.assets/designment.png)

## Progress

- [x] MCtrl

- [x] ICache

- [x] IFetcher

- [x] Issue

  - 关于 JALR 的处理： 丢给 ALU 算完以后直接发给 PC

- [x] RoB

- [x] RS

- [x] LSB

- [x] DCache

- [x] ALU

- [x] Reg

- [ ] cpu.v

## TODO

连线

所有的初始化工作：rst 和 jp_wrong 做好