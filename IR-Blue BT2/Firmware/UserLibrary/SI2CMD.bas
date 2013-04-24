(*
*****************************************************************************
*  Name    : SI2C Library                                                   *
*  Author  : David John Barker                                              *
*  Notice  : Copyright (c) 2003 Mecanique                                   *
*          : All Rights Reserved                                            *
*  Date    : 25/07/05                                                       *
*  Version : 1.1                                                            *
*  Notes   : 1.1 Corrected 'NotAcknowledged' in WriteByte()                 *
*          :     Added WaitForWrite() routine                               *
*          : 1.0 Initial release                                            *
*****************************************************************************
*)
module SI2C

include "system.bas"

// SCL option...
#if IsOption(I2C_SCL) and not IsValidPortPin(I2C_SCL) 
   #error I2C_SCL, "Invalid option. I2C clock must be a valid port pin."
#endif
#option I2C_SCL = PORTB.1

// SDA option...
#if IsOption(I2C_SDA) and not IsValidPortPin(I2C_SDA) 
   #error I2C_SDA, "Invalid option. I2C data line must be a valid port pin."
#endif
#option I2C_SDA = PORTB.2

// configure SCL and SDA...
dim
   SCL as I2C_SCL.I2C_SCL@,
   SDA as I2C_SDA.I2C_SDA@
   
// SI2C constants...
public const 
   I2C_ACKNOWLEDGE = 0,       // acknowledge data bit (acknowledge)
   I2C_NOT_ACKNOWLEDGE = 1    // acknowledge data bit (NOT acknowledge)

public dim
   NotAcknowledged as boolean
{
****************************************************************************
* Name    : Delay (PRIVATE)                                                *
* Purpose : Delay a fixed number of microseconds                           *
****************************************************************************
}
inline sub Delay()
   delayus(5)
end sub
{
****************************************************************************
* Name    : ToggleClock (PRIVATE)                                          *
* Purpose : Clock the I2C bus                                              *
****************************************************************************
}
inline sub ToggleClock()
   high(SCL)
   Delay
   low(SCL)
   Delay
end sub
{
****************************************************************************
* Name    : ShiftOut (PRIVATE)                                             *
* Purpose : Shift out a byte value, MSB first                              *
****************************************************************************
}
sub ShiftOut(pData as byte)
   dim Index as byte
   Index = 8
   repeat
      SDA = pData.7
      ToggleClock
      pData = pData << 1
      dec(Index)
   until Index = 0
   ClrWDT
end sub
{
****************************************************************************
* Name    : ShiftIn (PRIVATE)                                              *
* Purpose : Shift in a byte value, MSB first, sample before clock          *
****************************************************************************
}
function ShiftIn() as byte
   dim Index as byte
   Index = 8
   Result = 0
   input(SDA)
   repeat
      Result = Result << 1
      Result.0 = SDA
      ToggleClock
      dec(Index)
   until Index = 0
   output(SDA)
   ClrWDT
end function
{
****************************************************************************
* Name    : Initialize                                                     *
* Purpose : Initialize I2C bus                                             *
****************************************************************************
}         
public sub Initialize()
   high(SCL)    
   low(SDA) 
end sub
{
****************************************************************************
* Name    : Start                                                          *
* Purpose : Send an I2C bus start condition. A start condition is HIGH to  *
*         : LOW of SDA line when the clock is HIGH                         *
****************************************************************************
}         
public sub Start()
  SDA = 1
  Delay
  SCL = 1
  Delay
  SDA = 0
  Delay
  SCL = 0
  Delay
end sub
{
****************************************************************************
* Name    : Stop                                                           *
* Purpose : Send an I2C bus stop condition. A stop condition is LOW to     *
*         : HIGH of SDA when line when the clock is HIGH                   *
****************************************************************************
}         
public sub Stop()
  SDA = 0
  Delay
  SCL = 1
  Delay
  SDA = 1
  Delay
end sub
{
****************************************************************************
* Name    : Restart                                                        *
* Purpose : Send an I2C bus restart condition                              *
****************************************************************************
}         
public sub Restart()
   Start
end sub
{
****************************************************************************
* Name    : Acknowledge                                                    *
* Purpose : Initiate I2C acknowledge                                       *
*         : pAck = 1, NOT acknowledge                                      *
*         : pAck = 0, acknowledge                                          *
****************************************************************************
}         
public sub Acknowledge(pAck as bit = I2C_ACKNOWLEDGE)
   SDA = pAck
   ToggleClock 
end sub
{
****************************************************************************
* Name    : ReadByte (OVERLOAD)                                            *
* Purpose : Read a single byte from the I2C bus                            *
****************************************************************************
}         
public function ReadByte() as byte
   Result = ShiftIn
end function
{
****************************************************************************
* Name    : ReadByte (OVERLOAD)                                            *
* Purpose : Read a single byte from the I2C bus, with Acknowledge          *
****************************************************************************
}         
public function ReadByte(pAck as bit) as byte
  Result = ShiftIn
  Acknowledge(pAck)
end function
{
****************************************************************************
* Name    : WriteByte                                                      *
* Purpose : Write a single byte to the I2C bus                             *
****************************************************************************
}         
public sub WriteByte(pData as byte)
   ShiftOut(pData) 

   // look for ack...
   input(SDA)
   SDA = 1
   SCL = 1
   Delay
   NotAcknowledged = boolean(SDA)
   SCL = 0
   output(SDA)
end sub
{
****************************************************************************
* Name    : WaitForWrite                                                   *
* Purpose : Wait until write sequence has completed                        *
****************************************************************************
}         
public sub WaitForWrite(pControl as byte)
   dim Timeout as byte
   Timeout = $FF
          
   Start
   WriteByte(pControl)  
   while NotAcknowledged and (Timeout > 0)
      Restart
      WriteByte(pControl)  
      dec(Timeout)
   wend
   Stop
end sub
