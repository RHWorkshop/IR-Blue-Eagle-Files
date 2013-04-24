{
*****************************************************************************
*  Name    : Utils Library                                                  *
*  Author  : David John Barker                                              *
*  Notice  : Copyright (c) 2003 Mecanique                                   *
*          : All Rights Reserved                                            *
*  Date    : 25/06/05                                                       *
*  Version : 1.1                                                            *
*  Notes   :                                                                *
*          :                                                                *
*****************************************************************************
}
module Utils          
{
****************************************************************************
* Name    : Reverse (OVERLOAD)                                             *
* Purpose : Reverse the bits of pValue by pAmount                          *
****************************************************************************
}
public function Reverse(pValue as byte, pAmount as byte) as byte
   Result = 0
   while pAmount > 0
      Result = Result << 1
      Result.0 = pValue.0
      pValue = pValue >> 1
      dec(pAmount)
   wend
end function
{
****************************************************************************
* Name    : Reverse (OVERLOAD)                                             *
* Purpose : Reverse the bits of pValue by pAmount                          *
****************************************************************************
}
public function Reverse(pValue as word, pAmount as byte) as word
   Result = 0
   while pAmount > 0
      Result = Result << 1
      Result.0 = pValue.0
      pValue = pValue >> 1
      dec(pAmount)
   wend
end function
{
****************************************************************************
* Name    : Reverse (OVERLOAD)                                             *
* Purpose : Reverse the bits of pValue by pAmount                          *
****************************************************************************
}
public function Reverse(pValue as longword, pAmount as byte) as longword
   Result = 0
   while pAmount > 0
      Result = Result << 1
      Result.0 = pValue.0
      pValue = pValue >> 1
      dec(pAmount)
   wend
end function
{
****************************************************************************
* Name    : Digit (OVERLOAD)                                               *
* Purpose : Return the value of a decimal digit. For example, Digit(123,3) *
*         : will return the number 1                                       *
****************************************************************************
}
public function Digit(pValue as byte, pIndex as byte) as byte
   Result = 0
   while pIndex > 0
      Result = pValue mod 10
      pValue = pValue / 10
      dec(pIndex)
   wend
end function
{
****************************************************************************
* Name    : Digit (OVERLOAD)                                               *
* Purpose : Return the value of a decimal digit. For example, Digit(123,3) *
*         : will return the number 1                                       *
****************************************************************************
}
public function Digit(pValue as word, pIndex as byte) as byte
   Result = 0
   while pIndex > 0
      Result = pValue mod 10
      pValue = pValue / 10
      dec(pIndex)
   wend
end function
{
****************************************************************************
* Name    : Digit (OVERLOAD)                                               *
* Purpose : Return the value of a decimal digit. For example, Digit(123,3) *
*         : will return the number 1                                       *
****************************************************************************
}
public function Digit(pValue as longword, pIndex as byte) as byte
   Result = 0
   while pIndex > 0
      Result = pValue mod 10
      pValue = pValue / 10
      dec(pIndex)
   wend
end function
{
****************************************************************************
* Name    : Min (OVERLOAD)                                                 *
* Purpose : Return the minimum of two values                               *
****************************************************************************
}
public function Min(pValueA, pValueB as byte) as byte
   if pValueA < pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Min (OVERLOAD)                                                 *
* Purpose : Return the minimum of two values                               *
****************************************************************************
}
public function Min(pValueA, pValueB as shortint) as shortint
   if pValueA < pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Min (OVERLOAD)                                                 *
* Purpose : Return the minimum of two values                               *
****************************************************************************
}
public function Min(pValueA, pValueB as word) as word
   if pValueA < pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Min (OVERLOAD)                                                 *
* Purpose : Return the minimum of two values                               *
****************************************************************************
}
public function Min(pValueA, pValueB as integer) as integer
   if pValueA < pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Min (OVERLOAD)                                                 *
* Purpose : Return the minimum of two values                               *
****************************************************************************
}
public function Min(pValueA, pValueB as longword) as longword
   if pValueA < pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Min (OVERLOAD)                                                 *
* Purpose : Return the minimum of two values                               *
****************************************************************************
}
public function Min(pValueA, pValueB as longint) as longint
   if pValueA < pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Min (OVERLOAD)                                                 *
* Purpose : Return the minimum of two values                               *
****************************************************************************
}
public function Min(pValueA, pValueB as float) as float
   if pValueA < pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Max (OVERLOAD)                                                 *
* Purpose : Return the maximum of two values                               *
****************************************************************************
}
public function Max(pValueA, pValueB as byte) as byte
   if pValueA > pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Max (OVERLOAD)                                                 *
* Purpose : Return the maximum of two values                               *
****************************************************************************
}
public function Max(pValueA, pValueB as shortint) as shortint
   if pValueA > pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Max (OVERLOAD)                                                 *
* Purpose : Return the maximum of two values                               *
****************************************************************************
}
public function Max(pValueA, pValueB as word) as word
   if pValueA > pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Max (OVERLOAD)                                                 *
* Purpose : Return the maximum of two values                               *
****************************************************************************
}
public function Max(pValueA, pValueB as integer) as integer
   if pValueA > pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Max (OVERLOAD)                                                 *
* Purpose : Return the maximum of two values                               *
****************************************************************************
}
public function Max(pValueA, pValueB as longword) as longword
   if pValueA > pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Max (OVERLOAD)                                                 *
* Purpose : Return the maximum of two values                               *
****************************************************************************
}
public function Max(pValueA, pValueB as longint) as longint
   if pValueA > pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Max (OVERLOAD)                                                 *
* Purpose : Return the maximum of two values                               *
****************************************************************************
}
public function Max(pValueA, pValueB as float) as float
   if pValueA > pValueB then
      Result = pValueA
   else
      Result = pValueB
   endif
end function
{
****************************************************************************
* Name    : Swap (OVERLOAD)                                                *
* Purpose : Swap two values                                                *
****************************************************************************
}
public sub Swap(byref pValueA, pValueB as char)
   dim Tmp as char
   Tmp = pValueA
   pValueA = pValueB
   pValueB = Tmp
end sub
{
****************************************************************************
* Name    : Swap (OVERLOAD)                                                *
* Purpose : Swap two values                                                *
*         : NOTE : Will swap string with max 32 chars only                 *
****************************************************************************
}
public sub Swap(byref pValueA, pValueB as string)
   dim Tmp as string(33)
   Tmp = pValueA
   pValueA = pValueB
   pValueB = Tmp
end sub
{
****************************************************************************
* Name    : Swap (OVERLOAD)                                                *
* Purpose : Swap two values                                                *
****************************************************************************
}
public sub Swap(byref pValueA, pValueB as byte)
   dim Tmp as byte
   Tmp = pValueA
   pValueA = pValueB
   pValueB = Tmp
end sub
{
****************************************************************************
* Name    : Swap (OVERLOAD)                                                *
* Purpose : Swap two values                                                *
****************************************************************************
}
public sub Swap(byref pValueA, pValueB as shortint)
   dim Tmp as shortint
   Tmp = pValueA
   pValueA = pValueB
   pValueB = Tmp
end sub
{
****************************************************************************
* Name    : Swap (OVERLOAD)                                                *
* Purpose : Swap two values                                                *
****************************************************************************
}
public sub Swap(byref pValueA, pValueB as word)
   dim Tmp as word
   Tmp = pValueA
   pValueA = pValueB
   pValueB = Tmp
end sub
{
****************************************************************************
* Name    : Swap (OVERLOAD)                                                *
* Purpose : Swap two values                                                *
****************************************************************************
}
public sub Swap(byref pValueA, pValueB as integer)
   dim Tmp as integer
   Tmp = pValueA
   pValueA = pValueB
   pValueB = Tmp
end sub
{
****************************************************************************
* Name    : Swap (OVERLOAD)                                                *
* Purpose : Swap two values                                                *
****************************************************************************
}
public sub Swap(byref pValueA, pValueB as longword)
   dim Tmp as longword
   Tmp = pValueA
   pValueA = pValueB
   pValueB = Tmp
end sub
{
****************************************************************************
* Name    : Swap (OVERLOAD)                                                *
* Purpose : Swap two values                                                *
****************************************************************************
}
public sub Swap(byref pValueA, pValueB as longint)
   dim Tmp as longint
   Tmp = pValueA
   pValueA = pValueB
   pValueB = Tmp
end sub
{
****************************************************************************
* Name    : Swap (OVERLOAD)                                                *
* Purpose : Swap two values                                                *
****************************************************************************
}
public sub Swap(byref pValueA, pValueB as float)
   dim Tmp as float
   Tmp = pValueA
   pValueA = pValueB
   pValueB = Tmp
end sub
{
****************************************************************************
* Name    : HighNibble                                                     *
* Purpose : Returns the most significant nibble                            *
****************************************************************************
}
public inline function HighNibble(pValue as WREG) as byte
   Result = pValue >> 4
end function
{
****************************************************************************
* Name    : HighNibble                                                     *
* Purpose : Returns the least significant nibble                           *
****************************************************************************
}
public inline function LowNibble(pValue as WREG) as byte
   Result = pValue and $0F
end function
{
****************************************************************************
* Name    : SetAllDigital                                                  *
* Purpose : Switches device pins from analog to digital                    *
****************************************************************************
} 
public sub SetAllDigital()
  
  // 4 channels 
  #if _device in (18F1230, 18F1330)
  ADCON1 = $00
  CMCON = $07
  
  // 5 channels, ANSEL...
  #elseif _device in (18F2331, 18F2431)
  ANSEL0 = $00

  // 9 channels, ANSEL...
  #elseif _device in (18F4331, 18F4431)
  ANSEL0 = $00
  ANSEL1.0 = 0
  
  // 7 channels, bit field...
  #elseif _device in (18F1220, 18F1320)
  ADCON1 = $7F
  
  // 8 - 13 channels - 0 comp
  #elseif _comparator = 0
  ADCON1 = $0F

  // 13 channels, 2 comparators
  #elseif _device in (18F25K22)
  BSR = 15 
  ANSELA=0 
  ANSELB=0 
  ANSELC=0 
  BSR = 0 
  
  // J11 and J16 family...
  #elseif _device in (18F66J11, 18F66J16, 18F67J11, 18F86J11, 18F86J16, 18F87J11)
  ANCON0 = $FF
  ANCON1 = $FF

  // J50 and J55 family...
  #elseif _device in (18F65J50, 18F66J50, 18F66J55, 18F67J50, 18F85J50, 18F86J50, 18F86J55, 18F87J50)
  ANCON0 = $FF
  ANCON1 = $FF
  
  #else
  ADCON1 = $0F
  CMCON = $07
  #endif
end sub




