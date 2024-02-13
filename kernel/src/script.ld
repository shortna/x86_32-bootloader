ENTRY(kernel_main)

SECTIONS 
{
  . = 0x100000;
  .start :
  {
    *.(start)
  }
  .text : 
  { 
    *.(text)
  }
}
