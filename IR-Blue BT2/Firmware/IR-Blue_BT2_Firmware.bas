  // Info hardware setup: New PCB December 2012
  // PortA
  // RA0 = NC
  // RA1 = NC
  // RA2 = NC
  // RA3 = NC
  // RA4 = NC
  // RA5 = NC
  // RA6 = reserved for X-tal (Optional)
  // RA7 = reserved for X-tal (Optional)
  // PortB
  // RB0 = NC
  // RB1 = I2C SCL2    Connected to MLX90620 FIR sensor
  // RB2 = I2C SDA2    Connected to MLX90620 FIR sensor
  // RB3 = BT Interrupt input
  // RB4 = NC
  // RB6 = Serial2 TX   connected to RX bluetooth module
  // RB7 = Serial2 RX   connected to TX bluetooth module
  // PortC
  // RC0 = NC
  // RC1 = NC
  // RC2 = NC
  // RC3 = I2C SCL    Connected to MLX90620 FIR sensor
  // RC4 = I2C SDA    Connected to MLX90620 FIR sensor
  // RC5 = P-FET power switch Bluetooth module (Optional)
  // RC6 = Serial TX       'Button input (Optional)
  // RC7 = Serial RX       'NC

Device = 18F25k22
Clock =  64          '64MHz (top speed)

Config Debug = Off,         ' Background debugger disabled' RB6 and RB7 configured as general purpose I/O pins
    WDTEN = Off,         ' WDT disabled (control is placed on SWDTEN bit)
    'FOSC = INTIO67,         ' Internal oscillator block
    FOSC = HSHP,            'External crystal High Speed High Power
    'PLLCFG = Off,         ' Oscillator multiplied by 4
    XINST = Off,         ' Extra Instruction Set Disabled
    FCMEN = Off ,         ' Fail-Safe Clock Monitor enabled
    IESO = Off ,         ' Oscillator Switchover mode disabled
    PWRTEN = On,         ' PWRT
    BOREN = On ,         ' Brown-out Reset enabled and controlled by software (SBOREN is enabled)
    BORV = 190 ,         ' VBOR set to 1.9 V nominal
    WDTPS = 32768,         ' 1:32768
    MCLRE = EXTMCLR,     ' MCLR pin enabled, RE3 input pin disabled
    HFOFST = On,        ' The system clock is held off until the HF-INTOSC is stable.
    PRICLKEN = On,       ' Primary clock enabled
    PBADEN = Off ,       ' PORTB<4:0> pins are configured as digital I/O on Reset
    CCP2MX = PORTC1,     ' CCP2 input/output is multiplexed with RC1
    CCP3MX = PORTB5,     ' P3A/CCP3 input/output is multiplexed with RB5
    T3CMX = PORTC0 ,     ' T3CKI is on RC0
    P2BMX = PORTB5 ,     ' P2B is on RB5
    STVREN = On,         ' Stack full/underflow will cause Reset
    LVP = Off  ,         ' Single-Supply ICSP disabled
    CP0 = Off  ,         ' Block 0 (000800-001FFFh) not code-protected
    CP1 = Off  ,         ' Block 1 (002000-003FFFh) not code-protected
    CPB = Off  ,         ' Boot block (000000-0007FFh) not code-protected
    CPD = Off  ,         ' Data EEPROM not code-protected
    WRT0 = Off ,         ' Block 0 (000800-001FFFh) not write-protected
    WRT1 = Off ,         ' Block 1 (002000-003FFFh) not write-protected
    WRTB = Off ,         ' Boot block (000000-0007FFh) not write-protected
    WRTC = Off ,         ' Configuration registers (300000-3000FFh) not write-protected
    WRTD = Off ,         ' Data EEPROM not write-protected
    EBTR0 = Off ,        ' Block 0 (000800-001FFFh) not protected from table reads executed in other blocks
    EBTR1 = Off ,        ' Block 1 (002000-003FFFh) not protected from table reads executed in other blocks
    EBTRB = Off          ' Boot block (000000-0007FFh) not protected from table reads executed in other blocks

#option USART_BRGH = true    
#option USART_BRG16 = true
// import libraries...
Include "Utils.bas"
Include "I2C.bas"
Include "I2C2_18F25K22.bas"
'Include "USART2.bas"
Include "USART.bas"
Include "USART2_18F25K22.bas"
Include "convert.bas"
Include "ISRRX.bas"
Include "ISRRX2.bas"


'#option I2C_SCL = PORTB.1
'#option I2C_SDA = PORTB.2


Dim IRDATA(64) As Integer
Dim IRDATA2(64) As Integer
Dim EEPROM_DATA(256) As Byte
Dim RXDATA As String(5)

'
Dim xl As Byte
Dim CFG As Word
Dim PIX As Integer
Dim CFG2 As Word
Dim PIX2 As Integer
Dim CPIX As Integer
Dim CPIX2 As Integer
Dim PTAT As Integer
Dim PTAT2 As Integer
Dim EEDATA2  As Byte
Dim Flag As Boolean
Dim PacketReceived As Boolean 
Dim ReadPacket As Boolean 
Dim MessageLength As Byte
Dim LoopDelay As Integer
Dim Hz As Byte


// MLX90620 DATASHEET
Const MLX90620_ADDRESS = $60        // Melexis IR array I2C2 slave address
Const MLX90620_EEPROM_ADDRESS = $50 // 256x8 EEPROM I2C2 slave address for config values  (22AA02 Mircochip)
Const MLX90620_WRITEBIT = $C0       // Melexis IR array I2C2 write bit
Const MLX90620_PTAT = $90           // PTAT register ambient temperature
Const MLX90620_CPIX = $91           // Compensation pixel read register
Const MLX90620_Config = $92         // Configuration register
//Config register
//15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0 Configuration register bit meaning ($92)
//                              0 0 0 0 - IR Refresh rate = 512Hz
//                              0 0 0 1 - IR Refresh rate = 512Hz
//                              0 0 1 0 - IR Refresh rate = 512Hz
//                              0 0 1 1 - IR Refresh rate = 512Hz
//                              0 1 0 0 - IR Refresh rate = 512Hz
//                              0 1 0 1 - IR Refresh rate = 512Hz
//                              0 1 1 0 - IR Refresh rate = 256Hz
//                              0 1 1 1 - IR Refresh rate = 128Hz
//                              1 0 0 0 - IR Refresh rate = 64Hz
//                              1 0 0 1 - IR Refresh rate = 32Hz
//                              1 0 1 0 - IR Refresh rate = 16Hz
//                              1 0 1 1 - IR Refresh rate = 8Hz
//                              1 1 0 0 - IR Refresh rate = 4Hz
//                              1 1 0 1 - IR Refresh rate = 2Hz
//                              1 1 1 0 - IR Refresh rate = 1Hz (default)
//                              1 1 1 1 - IR Refresh rate = 0.5Hz
//                          x x - NA
//                        0 - Continuous measurement mode (default)
//                        1 - Step measurement mode
//                      0 - Normal operation mode (default)
//                      1 - Sleep mode
//                    0 - No Ta measurement running (flag only can not be written)
//                    1 - Ta measurement running (flag only can not be written)
//                  0 - No IR measurement running (flag only can not be written)
//                  1 - IR measurement running (flag only can not be written)
//               0 - POR or Brown-out occurred - Need to reload Configuration register
//               1 - MD must write "1" during uploading Confuguration register (default)
//            0 - I2C2 FM+ mode eneabled (max bit transfer rates up to 1000 kbit/s) (default)
//            1 - I2C2 FM+ mode disabled (max bit transfer rates up to 400 kbit/s)
//      0  0 - Ta Refresh rate = 16Hz
//      0  1 - Ta Refresh rate = 8Hz
//      1  0 - Ta Refresh rate = 4Hz
//      1  1 - Ta Refresh rate = 2Hz (default)
//   0 - ADC high reference enabled
//   1 - ADC low reference enabled
//X - NA
Const MLX90620_Trimming = $93       // Oscillator Trimming register
//15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0 Trimming register bit meaning ($93)
//                        7 bit value   - Oscillator trim value
//x  x  x  x  x  x  x x x               - NA
Const MLX90620_FIRST_RAM = $00      // IR RAM first address
Const MLX90620_LAST_RAM = $3F       // IR RAM last address
Const MLX90620_CMD_Dump = $00       // Command bulk reading EEPROM memory
Const MLX90620_CMD_Reading = $02    // Command reading
Const MLX90620_CMD_Writing = $03    // Command writing
Const MLX90620_CMD_Start_Measurement = $0801    // Command start measuring in step Mode


// IO symbols Small PCB
'Dim BT_STATUS As  PORTB.2    'Bluetooth module LED status blink=no connection
'Dim BT_INT As  PORTB.3       'Bluetooth module interrupt
'Dim SWITCH1 As  PORTC.6      'Optional switch input
'Dim BLUETOOTH As  PORTC.5    'Optional On/off output BT module

// IO symbols  Large PCB
'Dim LED1 As  PORTC.2
'Dim LED2 As  PORTC.7
'Dim IO1 As  PORTA.0
'Dim IO2 As  PORTA.1
'Dim IO3 As  PORTA.2
'Dim IO4 As  PORTA.3
'Dim SWITCH1 As  PORTC.6
'Dim BLUETOOTH As  PORTC.5

 Sub OnData() 
    If ISRRX.DataChar = "H" Then    'Start of packet received 
        Hz = Hz + 1
        If Hz > 5 Then
           Hz = 1
        EndIf
        PacketReceived = True 
    EndIf 
    ISRRX.ProcessByte = False   ' Don't buffer this char
End Sub

{
Sub OnData() 
    If ISRRX.DataChar = "#" Then    'Start of packet received 
        ISRRX.ProcessByte = False   ' Don't buffer this char
        ReadPacket = True            ' Start of acket received
        PacketReceived = False 
        MessageLength = 0 
    else
        If ISRRX.DataChar = "/" Then    'End of packet received 
            ReadPacket = False 
            PacketReceived = True 
        else
            ISRRX.ProcessByte = ReadPacket             
        EndIf 
    EndIf 
    
    If ReadPacket = True Then 
        Inc(MessageLength) 
        If MessageLength > 6 Then
           MessageLength = 0
           ISRRX.Reset
           ReadPacket = False 
           PacketReceived = False 
        EndIf
      
    EndIf 

End Sub
}

{
****************************************************************************
* Name    : read_EEPROM                                                    *
* Purpose : Read from one address I2C2 EEPROM - uses 2 byte address                     *
****************************************************************************
}         
Sub read_EEPROM(EEPROM_Addr As Word)
  I2C.Start           // issue I2C2 start signal
  I2C.WriteByte($A0)          // send byte via I2C2  (device address + W)
  I2C.WriteByte(EEPROM_Addr >> 8)      // send byte (MSB data address)
  I2C.WriteByte((EEPROM_Addr And $FF))   // send byte (LSB data address)
  I2C.Restart  // issue I2C2 signal repeated start
  I2C.WriteByte($A1)          // send byte (device address + R)
  EEDATA2 = I2C.ReadByte      // Read the data (acknowledge)
  ''I2C2.Acknowledge(I2C_NOT_ACKNOWLEDGE)
  I2C.Stop
End Sub

{
****************************************************************************
* Name    : read_EEPROM_MLX90620                                           *
* Purpose : Read from 64 addresses I2C2 EEPROM - uses 2 byte address        *
****************************************************************************
}
Sub read_EEPROM_MLX90620()
  //Read all contents of the EEPROM
  //and store it in an array
  I2C.Start                    // issue I2C2 start signal
  I2C.WriteByte($A0)          // send byte via I2C2  (device address + W)
  I2C.WriteByte($00)          // send byte (command)
  I2C.Restart                  // issue I2C2 signal repeated start
  I2C.WriteByte($A1)          // send byte (device address + R)
  For xl = 0 To 255
      EEPROM_DATA(xl) = I2C.ReadByte      // Read the data (acknowledge)
      I2C.Acknowledge(I2C_ACKNOWLEDGE)
  Next 
  'I2C.Acknowledge(I2C_NOT_ACKNOWLEDGE)
  I2C.Stop
End Sub
{
****************************************************************************
* Name    : Start_CMD_MLX90620                                             *
* Purpose : start measurement command in step mode                         *
****************************************************************************
}
Sub Start_CMD_MLX90620()
//
  I2C.Start           // issue I2C2 start signal
  I2C.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C.WriteByte($01)          // send byte LSB
  I2C.WriteByte($08)          // send byte MSB
  I2C.Stop
End Sub

{
****************************************************************************
* Name    : read_Config_Reg_MLX90620                                       *
* Purpose : read config register MLX90620                                  *
****************************************************************************
}
Sub read_Config_Reg_MLX90620()
  I2C.Start           // issue I2C2 start signal
  I2C.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C.WriteByte($02)          // send byte (command)
  I2C.WriteByte($92)          // send byte Address
  I2C.WriteByte($00)          // send byte Address step
  I2C.WriteByte($01)          // send byte number of reads
  I2C.Restart  // issue I2C2 signal repeated start
  I2C.WriteByte($C1)          // send byte (device address + R)
  CFG.Byte0 = I2C.ReadByte      // Read the data (acknowledge)
  I2C.Acknowledge(I2C_ACKNOWLEDGE)
  CFG.Byte1 = I2C.ReadByte      // Read the data (acknowledge)
  I2C.Acknowledge(I2C_ACKNOWLEDGE)
  I2C.Stop
End Sub

{
****************************************************************************
* Name    : read_Config_Reg_MLX90620                                       *
* Purpose : read config register MLX90620                                  *
****************************************************************************
}
Sub read2_Config_Reg_MLX90620()
  I2C2.Start           // issue I2C2 start signal
  I2C2.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C2.WriteByte($02)          // send byte (command)
  I2C2.WriteByte($92)          // send byte Address
  I2C2.WriteByte($00)          // send byte Address step
  I2C2.WriteByte($01)          // send byte number of reads
  I2C2.Restart  // issue I2C2 signal repeated start
  I2C2.WriteByte($C1)          // send byte (device address + R)
  CFG.Byte0 = I2C2.ReadByte      // Read the data (acknowledge)
  I2C2.Acknowledge(I2C_ACKNOWLEDGE)
  CFG.Byte1 = I2C2.ReadByte      // Read the data (acknowledge)
  I2C2.Acknowledge(I2C_ACKNOWLEDGE)
  I2C2.Stop
End Sub

{
****************************************************************************
* Name    : read_PTAT_Reg_MLX90620                                         *
* Purpose : read PTAT register MLX90620                                    *
****************************************************************************
}
Sub read_PTAT_Reg_MLX90620()
  I2C.Start                   // issue I2C2 start signal
  I2C.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C.WriteByte($02)          // send byte (command)
  I2C.WriteByte($90)          // send byte Address
  I2C.WriteByte($00)          // send byte Address step
  I2C.WriteByte($01)          // send byte number of reads
  I2C.Restart                 // issue I2C2 signal repeated start
  I2C.WriteByte($C1)          // send byte (device address + R)
  PTAT.Byte0 = I2C.ReadByte     // Read the data (acknowledge)
  I2C.Acknowledge(I2C_ACKNOWLEDGE)
  PTAT.Byte1 = I2C.ReadByte      // Read the data (acknowledge)
  I2C.Acknowledge(I2C_ACKNOWLEDGE)
  I2C.Stop
  'PTAT = (PTAT_MSB << 8) + PTAT_LSB
End Sub

{
****************************************************************************
* Name    : read_PTAT_Reg_MLX90620                                         *
* Purpose : read PTAT register MLX90620                                    *
****************************************************************************
}
Sub read2_PTAT_Reg_MLX90620()
  I2C2.Start                   // issue I2C2 start signal
  I2C2.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C2.WriteByte($02)          // send byte (command)
  I2C2.WriteByte($90)          // send byte Address
  I2C2.WriteByte($00)          // send byte Address step
  I2C2.WriteByte($01)          // send byte number of reads
  I2C2.Restart                 // issue I2C2 signal repeated start
  I2C2.WriteByte($C1)          // send byte (device address + R)
  PTAT2.Byte0 = I2C2.ReadByte     // Read the data (acknowledge)
  I2C2.Acknowledge(I2C_ACKNOWLEDGE)
  PTAT2.Byte1 = I2C2.ReadByte      // Read the data (acknowledge)
  I2C2.Acknowledge(I2C_ACKNOWLEDGE)
  I2C2.Stop
  'PTAT = (PTAT_MSB << 8) + PTAT_LSB
End Sub

{
****************************************************************************
* Name    : read_CPIX_Reg_MLX90620                                         *
* Purpose : read CPIX register MLX90620                                    *
****************************************************************************
}
Sub read_CPIX_Reg_MLX90620()
  I2C.Start           // issue I2C2 start signal
  I2C.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C.WriteByte($02)          // send byte (command)
  I2C.WriteByte($91)          // send byte Address
  I2C.WriteByte($00)          // send byte Address step
  I2C.WriteByte($01)          // send byte number of reads
  I2C.Restart  // issue I2C2 signal repeated start
  I2C.WriteByte($C1)          // send byte (device address + R)
  CPIX.Byte0 = I2C.ReadByte      // Read the data (acknowledge)
  I2C.Acknowledge(I2C_ACKNOWLEDGE)
  CPIX.Byte1 = I2C.ReadByte      // Read the data (acknowledge)
  I2C.Acknowledge(I2C_ACKNOWLEDGE)
  I2C.Stop
End Sub

{
****************************************************************************
* Name    : read_CPIX_Reg_MLX90620                                         *
* Purpose : read CPIX register MLX90620                                    *
****************************************************************************
}
Sub read2_CPIX_Reg_MLX90620()
  I2C2.Start           // issue I2C2 start signal
  I2C2.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C2.WriteByte($02)          // send byte (command)
  I2C2.WriteByte($91)          // send byte Address
  I2C2.WriteByte($00)          // send byte Address step
  I2C2.WriteByte($01)          // send byte number of reads
  I2C2.Restart  // issue I2C2 signal repeated start
  I2C2.WriteByte($C1)          // send byte (device address + R)
  CPIX2.Byte0 = I2C2.ReadByte      // Read the data (acknowledge)
  I2C2.Acknowledge(I2C_ACKNOWLEDGE)
  CPIX2.Byte1 = I2C2.ReadByte      // Read the data (acknowledge)
  I2C2.Acknowledge(I2C_ACKNOWLEDGE)
  I2C2.Stop
End Sub

{
****************************************************************************
* Name    : read_IR_Pix_MLX90620                                           *
* Purpose : read one IR pixel of MLX90620                                  *
****************************************************************************
}
Sub read_IR_Pix_MLX90620(pixel As Byte)
  I2C2.Start           // issue I2C2 start signal
  I2C2.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C2.WriteByte($02)          // send byte (command)
  I2C2.WriteByte(pixel)          // send byte Address
  I2C2.WriteByte($00)          // send byte Address step
  I2C2.WriteByte($01)          // send byte number of reads
  I2C2.Restart  // issue I2C2 signal repeated start
  I2C2.WriteByte($C1)          // send byte (device address + R)
  PIX.Byte0 = I2C2.ReadByte      // Read the data (acknowledge)
  I2C2.Acknowledge(I2C_ACKNOWLEDGE)
  PIX.Byte1 = I2C2.ReadByte      // Read the data (acknowledge)
  I2C2.Acknowledge(I2C_ACKNOWLEDGE)
  I2C2.Stop
  IRDATA(pixel) = PIX
End Sub

{
****************************************************************************
* Name    : read_IR_ALL_MLX90620                                           *
* Purpose : read all IR pixels of MLX90620                                 *
****************************************************************************
}
Sub read_IR_ALL_MLX90620()
  I2C.Start           // issue I2C start signal
  I2C.WriteByte($C0)          // send byte via I2C  (device address + W)
  I2C.WriteByte($02)          // send byte (command)
  I2C.WriteByte($00)          // send byte Address
  I2C.WriteByte($01)          // send byte Address step
  I2C.WriteByte($40)          // send byte number of reads
  I2C.Restart  // issue I2C signal repeated start
  I2C.WriteByte($C1)          // send byte (device address + R)
// convert data to 16 bits
  For xl = 0 To 63
      PIX.Byte0 = I2C.ReadByte      // Read the data (acknowledge)
      I2C.Acknowledge(I2C_ACKNOWLEDGE)
      PIX.Byte1 = I2C.ReadByte      // Read the data (acknowledge)
      I2C.Acknowledge(I2C_ACKNOWLEDGE)
      IRDATA(xl) = PIX
  Next 
  I2C.Stop
End Sub

{
****************************************************************************
* Name    : read_IR_ALL_MLX90620                                           *
* Purpose : read all IR pixels of MLX90620                                 *
****************************************************************************
}
Sub read2_IR_ALL_MLX90620()
  I2C2.Start           // issue I2C2 start signal
  I2C2.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C2.WriteByte($02)          // send byte (command)
  I2C2.WriteByte($00)          // send byte Address
  I2C2.WriteByte($01)          // send byte Address step
  I2C2.WriteByte($40)          // send byte number of reads
  I2C2.Restart  // issue I2C2 signal repeated start
  I2C2.WriteByte($C1)          // send byte (device address + R)
// convert data to 16 bits
  For xl = 0 To 63
      PIX2.Byte0 = I2C2.ReadByte      // Read the data (acknowledge)
      I2C2.Acknowledge(I2C_ACKNOWLEDGE)
      PIX2.Byte1 = I2C2.ReadByte      // Read the data (acknowledge)
      I2C2.Acknowledge(I2C_ACKNOWLEDGE)
      IRDATA2(xl) = PIX2
  Next 
  I2C2.Stop
End Sub

{
****************************************************************************
* Name    : config_MLX90620_0_5Hz                                          *
* Purpose : set sensor speed to 0.5 Hz                                     *
****************************************************************************
}
Sub config_MLX90620_0_5Hz()
//config value $740E default and POR set (cleared)
//default settings
  I2C.Start                   // issue I2C start signal
  I2C.WriteByte($C0)          // send byte via I2C  (device address + W)
  I2C.WriteByte($03)          // send byte (command)
  I2C.WriteByte($BA)          // send byte LSB check
  I2C.WriteByte($0F)          // send byte LSB
  I2C.WriteByte($1F)          // send byte MSB check
  I2C.WriteByte($74)          // send byte MSB
  I2C.Stop
End Sub

{
****************************************************************************
* Name    : config2_MLX90620_0_5Hz                                          *
* Purpose : set sensor 2 speed to 0.5 Hz                                     *
****************************************************************************
}
Sub config2_MLX90620_0_5Hz()
//config value $740E default and POR set (cleared)
//default settings
  I2C2.Start           // issue I2C2 start signal
  I2C2.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C2.WriteByte($03)          // send byte (command)
  I2C2.WriteByte($BA)          // send byte LSB check
  I2C2.WriteByte($0F)          // send byte LSB
  I2C2.WriteByte($1F)          // send byte MSB check
  I2C2.WriteByte($74)          // send byte MSB
  I2C2.Stop
End Sub


{
****************************************************************************
* Name    : config_MLX90620_1Hz                                            *
* Purpose : set sensor speed to 1 Hz                                       *
****************************************************************************
}
Sub   config_MLX90620_1Hz()
//config value $740E default and POR set (cleared)
//default settings
  I2C.Start           // issue I2C start signal
  I2C.WriteByte($C0)          // send byte via I2C  (device address + W)
  I2C.WriteByte($03)          // send byte (command)
  I2C.WriteByte($B9)          // send byte LSB check
  I2C.WriteByte($0E)          // send byte LSB
  I2C.WriteByte($1F)          // send byte MSB check
  I2C.WriteByte($74)          // send byte MSB
  I2C.Stop
End Sub

{
****************************************************************************
* Name    : config2_MLX90620_1Hz                                            *
* Purpose : set sensor 2 speed to 1 Hz                                       *
****************************************************************************
}
Sub   config2_MLX90620_1Hz()
//config value $740E default and POR set (cleared)
//default settings
  I2C2.Start           // issue I2C2 start signal
  I2C2.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C2.WriteByte($03)          // send byte (command)
  I2C2.WriteByte($B9)          // send byte LSB check
  I2C2.WriteByte($0E)          // send byte LSB
  I2C2.WriteByte($1F)          // send byte MSB check
  I2C2.WriteByte($74)          // send byte MSB
  I2C2.Stop
End Sub


{
****************************************************************************
* Name    : config_MLX90620_2Hz                                            *
* Purpose : set sensor speed to 2 Hz                                       *
****************************************************************************
}
Sub   config_MLX90620_2Hz()
//config value $740D 2Hz and POR set (cleared)
//default settings
  I2C.Start           // issue I2C start signal
  I2C.WriteByte($C0)          // send byte via I2C  (device address + W)
  I2C.WriteByte($03)          // send byte (command)
  I2C.WriteByte($B8)          // send byte LSB check
  I2C.WriteByte($0D)          // send byte LSB
  I2C.WriteByte($1F)          // send byte MSB check
  I2C.WriteByte($74)          // send byte MSB
  I2C.Stop
End Sub

{
****************************************************************************
* Name    : config2_MLX90620_2Hz                                            *
* Purpose : set sensor speed to 2 Hz                                       *
****************************************************************************
}
Sub   config2_MLX90620_2Hz()
//config value $740D 2Hz and POR set (cleared)
//default settings
  I2C2.Start           // issue I2C start signal
  I2C2.WriteByte($C0)          // send byte via I2C  (device address + W)
  I2C2.WriteByte($03)          // send byte (command)
  I2C2.WriteByte($B8)          // send byte LSB check
  I2C2.WriteByte($0D)          // send byte LSB
  I2C2.WriteByte($1F)          // send byte MSB check
  I2C2.WriteByte($74)          // send byte MSB
  I2C2.Stop
End Sub


{
****************************************************************************
* Name    : config_MLX90620_4Hz                                            *
* Purpose : set sensor speed to 4 Hz                                       *
****************************************************************************
}
Sub   config_MLX90620_4Hz()
//config value $740C 4Hz and POR set (cleared)
//default settings
  I2C.Start           // issue I2C start signal
  I2C.WriteByte($C0)          // send byte via I2C  (device address + W)
  I2C.WriteByte($03)          // send byte (command)
  I2C.WriteByte($B7)          // send byte LSB check
  I2C.WriteByte($0C)          // send byte LSB
  I2C.WriteByte($1F)          // send byte MSB check
  I2C.WriteByte($74)          // send byte MSB
  I2C.Stop
End Sub



{
****************************************************************************
* Name    : config2_MLX90620_4Hz                                            *
* Purpose : set sensor 2speed to 4 Hz                                       *
****************************************************************************
}
Sub   config2_MLX90620_4Hz()
//config value $740C 4Hz and POR set (cleared)
//default settings
  I2C2.Start           // issue I2C2 start signal
  I2C2.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C2.WriteByte($03)          // send byte (command)
  I2C2.WriteByte($B7)          // send byte LSB check
  I2C2.WriteByte($0C)          // send byte LSB
  I2C2.WriteByte($1F)          // send byte MSB check
  I2C2.WriteByte($74)          // send byte MSB
  I2C2.Stop
End Sub

{
****************************************************************************
* Name    : config_MLX90620_8Hz                                            *
* Purpose : set sensor speed to 8 Hz                                       *
****************************************************************************
}
Sub   config_MLX90620_8Hz()
//config value $740B 4Hz and POR set (cleared)
//default settings
  I2C.Start           // issue I2C2 start signal
  I2C.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C.WriteByte($03)          // send byte (command)
  I2C.WriteByte($B6)          // send byte LSB check
  I2C.WriteByte($0B)          // send byte LSB
  I2C.WriteByte($1F)          // send byte MSB check
  I2C.WriteByte($74)          // send byte MSB
  I2C.Stop
End Sub

{
****************************************************************************
* Name    : config2_MLX90620_8Hz                                            *
* Purpose : set sensor 2 speed to 8 Hz                                       *
****************************************************************************
}
Sub   config2_MLX90620_8Hz()
//config value $740B 4Hz and POR set (cleared)
//default settings
  I2C2.Start           // issue I2C2 start signal
  I2C2.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C2.WriteByte($03)          // send byte (command)
  I2C2.WriteByte($B6)          // send byte LSB check
  I2C2.WriteByte($0B)          // send byte LSB
  I2C2.WriteByte($1F)          // send byte MSB check
  I2C2.WriteByte($74)          // send byte MSB
  I2C2.Stop
End Sub


{
****************************************************************************
* Name    : config_MLX90620_16Hz                                           *
* Purpose : set sensor speed to 16 Hz                                      *
****************************************************************************
}
Sub   config_MLX90620_16Hz()
//config value $740A 4Hz and POR set (cleared)
//default settings
  I2C.Start           // issue I2C2 start signal
  I2C.WriteByte($C0)          // send byte via I2C2  (device address + W)
  I2C.WriteByte($03)          // send byte (command)
  I2C.WriteByte($B5)          // send byte LSB check
  I2C.WriteByte($0A)          // send byte LSB
  I2C.WriteByte($1F)          // send byte MSB check
  I2C.WriteByte($74)          // send byte MSB
  I2C.Stop
End Sub

{
****************************************************************************
* Name    : config2_MLX90620_16Hz                                           *
* Purpose : set sensor 2 speed to 16 Hz                                      *
****************************************************************************
}
Sub   config2_MLX90620_16Hz()
//config value $740A 4Hz and POR set (cleared)
//default settings
  I2C2.Start           // issue I2C start signal
  I2C2.WriteByte($C0)          // send byte via I2C  (device address + W)
  I2C2.WriteByte($03)          // send byte (command)
  I2C2.WriteByte($B5)          // send byte LSB check
  I2C2.WriteByte($0A)          // send byte LSB
  I2C2.WriteByte($1F)          // send byte MSB check
  I2C2.WriteByte($74)          // send byte MSB
  I2C2.Stop
End Sub

{
****************************************************************************
* Name    : SetRefresh                                                     *
* Purpose : Set refresh rate FIR sensor 0.5Hz to 16Hz                      *
****************************************************************************
}

Sub SetRefresh()

    Select Hz
        Case 1 
            config_MLX90620_0_5Hz
            LoopDelay = 990
        Case 2 
            config_MLX90620_1Hz
            LoopDelay = 990
        Case 3 
            config_MLX90620_2Hz
            LoopDelay = 490
        Case 4 
            config_MLX90620_4Hz
            LoopDelay = 240
        Case 5 
            config_MLX90620_8Hz
            LoopDelay = 120
        Case 6 
            config_MLX90620_16Hz
            LoopDelay = 60                        
    EndSelect        
    DelayMS(100)
End Sub

{
****************************************************************************
* Name    : check_Config_Reg_MLX90620                                      *
* Purpose : check config register BOR bit for power failure                *
****************************************************************************
}
Sub check_Config_Reg_MLX90620()
    read_Config_Reg_MLX90620
    If (CFG.Byte1 And $04) = 0 Then
        SetRefresh
    EndIf
End Sub

{
****************************************************************************
* Name    : check_Config_Reg_MLX90620                                      *
* Purpose : check config register BOR bit for power failure                *
****************************************************************************
}
Sub check2_Config_Reg_MLX90620()
    read2_Config_Reg_MLX90620
    If (CFG.Byte1 And $04) = 0 Then
        SetRefresh
    EndIf
End Sub




{
****************************************************************************
* Name    : EEPROM_Serial_Transmit                                         *
* Purpose : Transmit EEPROM data through serial port                      *
****************************************************************************
}
Sub EEPROM_Serial_Transmit()
    USART.Write("E")                           //EEPROM data begin
    For xl = 0 To 255 //255
      'USART.Write(DecToStr(xl))               //EEPROM Address
      USART.Write(DecToStr(EEPROM_DATA(xl),3," "))
    Next 
      USART.Write("EX",13,10)                  //data end
End Sub

{
****************************************************************************
* Name    : IRDATA_Serial                                                  *
* Purpose : Transmit IR pixel and register data through serial port        *
****************************************************************************
}
Sub IRDATA_Serial()
    USART.Write("R")                      //Register data begin
    USART.Write(DecToStr(MLX90620_PTAT))  //PTAT register
    USART.Write(DecToStr((PTAT),6))       //2 bytes
    USART.Write(DecToStr(MLX90620_CPIX))  //CPIX register
    USART.Write(DecToStr((CPIX),6))
    USART.Write("I")         //IR data begin
    For xl = 0 To 63
        USART.Write(DecToStr(IRDATA(xl),6," "))  
        'USART.writeword(IRDATA(xl))  deze proberen!
    Next 
    USART.Write("X",13,10)         //data end
End Sub


{
****************************************************************************
* Name    : IRDATA2_Serial                                                  *
* Purpose : Transmit IR pixel and register data through serial port        *
****************************************************************************
}
Sub IRDATA2_Serial()
    USART.Write("R")                      //Register data begin
    USART.Write(DecToStr(MLX90620_PTAT))  //PTAT register
    USART.Write(DecToStr((PTAT),6))       //2 bytes
    USART.Write(DecToStr(MLX90620_CPIX))  //CPIX register
    USART.Write(DecToStr((CPIX),6))
    USART.Write("D")         //IR data begin
    For xl = 0 To 63
        USART.Write(DecToStr(IRDATA2(xl),6," "))       
    Next 
    USART.Write("X",13,10)         //data end
End Sub


//   Main program
    OSCCON = %01110000     ' 16Mhz intern osc
    OSCCON2 = %10000100    ' select PLL as osc source
    OSCTUNE= %01000000     ' 4x PLL results in 64Mhz
    
      PORTA = $00
      PORTB = $00
      PORTC = $00
      ANSELA  = 0       ' Configure AN pins as digital I/O
      ANSELB  = 0       ' Configure AN pins as digital I/O
      ANSELC  = 0       ' Configure AN pins as digital I/O
      TRISA = $00       ' set direction to be output
      TRISB = %10111101 ' set direction
      TRISC = %01000000 ' set direction to be output
    
      SetAllDigital
      PacketReceived = False 
      ReadPacket = False
      'BLUETOOTH = 0 'Power on bluetooth module
      DelayMS(1000)
      SetBaudrate(br9600)              // Initialize UART module at 9600 bps
      DelayMS(1000)                      // Wait for UART module to stabilize
      USART.Write("AT")
      DelayMS(500)
      USART.Write("AT+NAMEIR-Blue-BT2")   //Set Bluetooth2 Name
      DelayMS(500)
      USART.Write("AT+BAUD8")  //Set Baud for the Bluetooth2 Module
      DelayMS(500)
      SetBaudrate(br115200)
      DelayMS(500)                      // Wait for UART module to stabilize
      USART.Write("AT+NAMEIR-Blue-BT2")   //Set Bluetooth2 Name

      'I2C2.Initialize(I2C_400_KHZ)
      'DelayMS(100)
      I2C.Initialize(I2C_400_KHZ)
      DelayMS(1000)
      Hz = 4  ' 4Hz refresh rate  
      SetRefresh
      DelayMS(100)
      'LED1 = 1
      'USART.Write("A")
      'USART.Write("A")
      'USART.Write("A")
      'USART.Write("A")
      'USART.Write("A")
      DelayMS(100)

      read_EEPROM_MLX90620
      USART.WaitForStr("R001")
      'LED1 = 0
      ISRRX.Initialize(@OnData)
      DelayMS(500)
      EEPROM_Serial_Transmit
      DelayMS(1000)
// Main Loop
      While TRUE
            ISRRX.Stop
            check_Config_Reg_MLX90620
            'check2_Config_Reg_MLX90620
            read_PTAT_Reg_MLX90620
            read_CPIX_Reg_MLX90620
            'DelayMS(25)
            read_IR_ALL_MLX90620
            IRDATA_Serial
            'isrrx.start
            'DelayMS(120)
            'isrrx.stop
            'read2_IR_ALL_MLX90620
            'IRDATA2_Serial
            'LED2 = 1
            ISRRX.Start
            If ISRRX.Overrun Then 
               ISRRX.Reset
               PacketReceived = False
            EndIf 
           
            If PacketReceived Then 
                   SetRefresh
                   ISRRX.Reset
                   PacketReceived = False 
            EndIf 
                   
            DelayMS(LoopDelay)
            'LED2 = 0
      Wend              // Endless loop

