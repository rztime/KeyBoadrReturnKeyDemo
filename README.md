# KeyBoadrReturnKeyDemo
 多文本输入框的return键设为next  done

设置
```
[RZKeyboardReturnKeyUtil shareInstance].enable = YES;
```

在当前viewcontroller中所有的输入框，按照约定最后一个输入框的键盘的return键为done（完成）点击之后关闭输入框，其他所有输入框的return键改为next（下一项），点击之后自动跳转到下一个输入框