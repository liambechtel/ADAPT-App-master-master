//
//  BLEController.swift
//  Target_MB
//
//  Created by Timmy Gouin on 12/13/17.
//  Copyright © 2017 Timmy Gouin. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import CoreData

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

func Endian_change(org:UInt32) -> UInt32 {
    var org2=org
    var new:UInt32=0
    for i in 1...4 {
        new*=256
        new+=org2%256
        org2=org2/256
    }
    return new
}

func hextoFloat(data_string:String) -> Float {
        var toInt = Int32(truncatingIfNeeded: strtol(data_string, nil, 16))
        var float1:Float=0.0000
        memcpy(&float1, &toInt, MemoryLayout.size(ofValue: float1))
        return float1
}
//extension String {
//    func asciiValueOfString() -> [UInt32] {
//
//        var retVal = [UInt32]()
//        for val in self.unicodeScalars {
//            retVal.append(UInt32(val))
//        }
//        return retVal
//    }
//}


class BLEController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    //CoreBluetooth Properties
    var centralManager:CBCentralManager!
    var sensorTile:CBPeripheral?
    static var shouldAutoconnect = true
    static var MAX_VALUE: Double = 655000000.0
    static var PERIPHERAL_UUID = "peripheral_uuid"
    //    static var SERVICE_UUID = "00000000-0001-11E1-9AB4-0002A5D5C51B" //for SensorTile
    //    static var CHARACTERISTIC_UUID = "00000100-0001-11E1-AC36-0002A5D5C51B" //for SensorTile
    //static var SERVICE_UUID = "0000FFE0-0000-1000-8000-00805F9B34FB" //HM-10
    static var SERVICE_UUID = "0xFFE0" //HM-10
    static var CHARACTERISTIC_UUID = "0xFFE1"//HM-10
    var serviceUUID = CBUUID(string: BLEController.SERVICE_UUID)
    var characteristicUUID = CBUUID(string: BLEController.CHARACTERISTIC_UUID)
    var state:String?
    var data_packet = NSMutableData()
    var data_string = Data()
    var max: Int32 = 0
    
    var sensorTileName = "SensorTile"
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let nc = NotificationCenter.default
        if let savedPeripheralUUID = UserDefaults.standard.string(forKey: BLEController.PERIPHERAL_UUID){
            if (BLEController.shouldAutoconnect && peripheral.identifier.uuidString == savedPeripheralUUID) {
                self.connect(peripheral: peripheral)
                nc.post(name:Notification.Name(rawValue:"SavedDeviceConnecting"), object: nil)
            }
        }
        //        nc.post(name:Notification.Name(rawValue:"DeviceFound"), object: peripheral)
        if let name = peripheral.name {
            print("NAME:")
            print("\(name)")
            if name == "YostLabsMBLE" {
                //                      if name == "AM1V340" {
                sensorTile = peripheral
                guard let unwrappedPeripheral = sensorTile else { return }
                unwrappedPeripheral.delegate = self
                centralManager.connect(unwrappedPeripheral, options: nil)
                
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //TODO: save peripheral for auto connect
        let defaults = UserDefaults.standard
        defaults.set(peripheral.identifier.uuidString, forKey: BLEController.PERIPHERAL_UUID)
        _ = UIApplication.shared.delegate
        
        peripheral.discoverServices([serviceUUID])
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        
        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                
                
                guard sensorTile != nil else { return }
                peripheral.setNotifyValue(true, for: characteristic)
                
                
                let setstream:[UInt8] = [0x3a ,0x38, 0x30, 0x2c, 0x31 ,0x2c ,0x32, 0x35, 0x35, 0x2c, 0x32, 0x35 ,0x35 ,0x2c, 0x32, 0x35 ,0x35 ,0x2c ,0x32 ,0x35, 0x35 ,0x2c, 0x32, 0x35, 0x35 ,0x2c, 0x32 ,0x35, 0x35, 0x2c, 0x32, 0x35 ,0x35, 0x5c, 0x6e];
                let setbaud:[UInt8] = [0x3a, 0x32, 0x33, 0x31, 0x2c, 0x39, 0x36 ,0x30, 0x30, 0x5c, 0x6e];
                let setdelay:[UInt8] = [0x3a, 0x38, 0x32, 0x2c ,0x35 ,0x30, 0x30, 0x30 ,0x30,0x30,0x2c ,0x32, 0x32, 0x35, 0x32, 0x32, 0x35, 0x32, 0x32, 0x35, 0x32, 0x32, 0x35, 0x2c, 0x31, 0x30 ,0x30, 0x30 ,0x5c, 0x6e];
                let savemode:[UInt8] = [0x3a, 0x32, 0x32, 0x35 ,0x5c ,0x6e];
                let softreset:[UInt8] = [0x3a, 0x32 ,0x32, 0x36, 0x5c, 0x6e];
                let startData:[UInt8] = [0x3a, 0x38, 0x35, 0x5c, 0x6e];
                let startTimeLengthData:[UInt8] = [0x3a, 0x38, 0x35, 0x5c, 0x6e];
                let startbin:[UInt8] = [0xf9, 0x55, 0x55];
                let setstreambin:[UInt8] = [0xf7, 0x50, 0x01, 0x51];
                let setdelaybin:[UInt8] = [0xf7, 0x52, 0x7a, 0x51];
                let eulerbin:[UInt8] = [0xf9,0x01,0x01]
                let eulerascii:[UInt8] = [0x3a,0x31,0x5c,0x6e]
                let setheader:[UInt8] = [0xf7,0xdd,0x00,0x00,0x00,0x50,0x2d]
                
                let setstreambyte = Data(bytes: setstream)
                let setbaudbyte = Data(bytes: setbaud)
                let setdelaybyte = Data(bytes: setdelay)
                let savemodebyte = Data(bytes: savemode)
                let resetbyte = Data(bytes: softreset)
                let startDatabyte = Data(bytes: startData)
                let startbinbyte = Data(bytes: startbin)
                let startstreambin = Data(bytes: setstreambin)
                let eulerbinbyte = Data(bytes: eulerbin)
                let eulerasciibyte = Data(bytes: eulerascii)
                let setheaderbyte = Data(bytes:setheader)
                
//                peripheral.writeValue(setstreambyte, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
//                peripheral.writeValue(eulerbinbyte, for: characteristic,type: CBCharacteristicWriteType.withoutResponse)
                peripheral.writeValue(setheaderbyte, for: characteristic,type: CBCharacteristicWriteType.withoutResponse)
                peripheral.writeValue(startbinbyte, for: characteristic,type: CBCharacteristicWriteType.withoutResponse)
                //               peripheral.writeValue(setbaudbyte, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
//                peripheral.writeValue(setdelaybyte, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                //  peripheral.writeValue(savemodebyte, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                //                peripheral.writeValue(resetbyte, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                
                
//                peripheral.writeValue(startbinbyte, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                
                print(peripheral)
                print(characteristic)
                print(service)
                return
            }
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if var value = characteristic.value {
            //let data = NSMutableData(data: value)
            //data_packet.appendData(data)
            data_string=Data()
            data_string.append(value)
            var raw:UInt32=0
            var hex_string=""
            var timestamp:Float=0;
            var counter:Int=0
            var yaw:Float=0;
            var pitch:Float=0;
            var roll:Float=0;
            var droll:Double=0;
            var dpitch:Double=0;
            var dyaw:Double=0;
            let packet_size = data_string.count
            let data = NSMutableData(data: data_string);
            data_string=Data()
            while(counter < (packet_size - 15)){//check if enough data present in packet
                while((raw != 0x0cfe)&&(counter < (packet_size - 15))){//check header
                    data.getBytes(&raw, range: NSMakeRange(counter,2))
                    counter+=1
                }
                if(counter>=(packet_size - 15)){//break if enough data not present
                    break
                }
                counter+=1
                data.getBytes(&raw, range: NSMakeRange(counter,4))
                raw=Endian_change(org:raw)
                hex_string=String(format:"%02X",raw)
                pitch = hextoFloat(data_string:hex_string)
                data.getBytes(&raw, range: NSMakeRange(counter+4,4))
                raw=Endian_change(org:raw)
                hex_string=String(format:"%02X",raw)
                yaw = hextoFloat(data_string:hex_string)
                data.getBytes(&raw, range: NSMakeRange(counter+8,4))
                raw=Endian_change(org:raw)
                hex_string=String(format:"%02X",raw)
                roll = hextoFloat(data_string:hex_string)//string to float
                dyaw = (Double)(yaw*180/3.14159265)//convert radians to degrees
                droll = (Double)(roll*180/3.14159265)
                dpitch = (Double)(pitch*180/3.14159265)
                let euler = Euler(yaw: dyaw, pitch: dpitch, roll: droll)
                //
                //                //print("Euler Angles: yaw: \(euler.yaw) pitch: \(euler.pitch) roll: \(euler.roll)")
                let nc = NotificationCenter.default
                ////                nc.post(name:Notification.Name(rawValue:"DeviceDataCHEST"), object: eulerCHEST)
                nc.post(name:Notification.Name(rawValue:"DeviceData"), object: euler)
            }
        }
    }
            
//            var dd:Float = 0.0000
            
            //            print("Value data: \(value)")
            //            print("Sensor value hex: \(value.hexEncodedString())")
            //            print("Sensor data raw: \(data)")
            //            print("Sensor value: \(value)")
            //            print(value.count)
            //            var stop:UInt16 = 0
//            if value.count == 11{
//                data.getBytes(&dd, range: NSMakeRange(4,4))
//            }else if value.count == 10{
//                data.getBytes(&dd, range: NSMakeRange(3,4))
//            }else{
//                data.getBytes(&dd, range: NSMakeRange(0,value.count))
//            }
            
//            var respBin:[UInt8] = [0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
//            if value.count == 1{
//                data.getBytes(&respBin, range: NSMakeRange(0,1))
//            }
//            else if value.count == 2{
//                data.getBytes(&respBin, range: NSMakeRange(0,2))
//            }
//            else{
//
//            }
            
            //Need to parse based on 0a (line break) - 10 and 2c (comma) - 44
            //parse values
            
//            print(dd)
            
            
            //            var x:Int = 0
            //            var found = false
            //            var i:Int = 0
            
            //                var timestamp:UInt16 = 0
            //                var yaw:Int16 = 0
            //                var pitch:Int16 = 0
            //                var roll:Int16 = 0
            //            var yawstring = ""
            //            var pitchstring = ""
            //            var rollstring = ""
            //
            //
            //            var d:Int16 = 0
            //            print("Length: \(value.count)")
            //
            //            while x < value.count{
            //                data.getBytes(&d, range: NSMakeRange(x,1))
            //                print("Index: \(x) , Data: \(d)")
            //
            //
            //                if found == true{
            //                    if d == 44{
            //                        x = x + 1
            //                        i = i + 1
            //
            //                    }else {
            //                        if d == 10{
            //                            found = false
            //                            x = x + 1
            //                        }else{
            //                            if i == 0{
            //                                yawstring.append(String(d))
            //                            }
            //                            if i == 1{
            //                                pitchstring.append(String(d))                            }
            //                            if i == 2{
            //                                rollstring.append(String(d))                            }
            //                            x = x+1
            //                        }
            //                    }
            //                }else if d == 10{
            //                    found = true
            //                    x = x + 1
            //                }else{
            //                    x = x + 1
            //                }
            //            }
            //
            //            //                            var timestamp = Int(
            //            let yawA = Array(yawstring)
            //            let pitchA = Array(pitchstring)
            //            let rollA = Array(rollstring)
            //
            //            var yawAstring: Array<String> = Array(repeating: "", count: yawstring.count/2)
            //            var pitchAstring: Array<String> = Array(repeating: "", count: pitchstring.count/2)
            //            var rollAstring: Array<String> = Array(repeating: "", count: rollstring.count/2)
            //
            //            var c:Int = 0
            //
            //            while c < yawA.count{
            //                let index1 = yawA[c]
            //                let index2 = yawA[c+1]
            //                let i = [index1 , index2]
            //                yawAstring[c/2] = String(i)
            //                c = c + 2
            //            }
            //            c = 0
            //            while c < pitchA.count{
            //                let index1 = pitchA[c]
            //                let index2 = pitchA[c+1]
            //                let i = [index1 , index2]
            //                pitchAstring[c/2] = String(i)
            //                c = c + 2
            //            }
            //            c = 0
            //            while c < rollA.count{
            //                let index1 = rollA[c]
            //                let index2 = rollA[c+1]
            //                let i = [index1 , index2]
            //                rollAstring[c/2] = String(String(i))
            //                c = c + 2
            //            }
            //            print(yawAstring)
            //            print(pitchAstring)
            //            print(rollAstring)
            //            while c < yawA.count/2{
            //
            //                yawA(c) = [Character](yawstring(c)+(yawstring(c+1)))
            //
            //            }
            //
            //
            //            print("raw yaw data: \(yaw)")
            ////            print("double yaw data: \(dYaw)")
            //
            //            print("raw pitch data: \(pitch)")
            ////            print("double pitch data: \(dPitch)")
            //
            //            print("raw roll data: \(roll)")
            //            print("double roll data: \(dRoll)")
            
            //            let dYaw = Double(yaw)/100
            //            let dPitch = Double(pitch)/100
            //            let dRoll = Double(roll)/100
            //                var yawCHEST:Int16 = 0
            //                data.getBytes(&yawCHEST, range: NSMakeRange(8, 2))
            //
            //                var pitchCHEST:Int16 = 0
            //                data.getBytes(&pitchCHEST, range: NSMakeRange(10, 2))
            //
            //                var rollCHEST:Int16 = 0
            //                data.getBytes(&rollCHEST, range: NSMakeRange(12, 2))
            //
            
            //var qS:Int32 = 0
            //data.getBytes(&qS, range: NSMakeRange(14, 4))
            //                var dQi = Double(qI)
            //                var dQj = Double(qJ)
            //                var dQk = Double(qK)
            //                var dQs = Double(qS)
            //                if (qI > max) {
            //                    max = qI
            //                }
            //                if (qJ > max) {
            //                    max = qJ
            //                }
            //                if (qK > max) {
            //                    max = qK
            //                }
            //                if (qS > max) {
            //                    max = qS
            //                }
            
            
            //                var dYaw = Double(yaw)
            //                var dPitch = Double(pitch)
            //                var dRoll = Double(roll)
            
            //                print("raw yaw data: \(yaw)")
            //                print("double yaw data: \(dYaw)")
            //
            //                print("raw pitch data: \(pitch)")
            //                print("double pitch data: \(dPitch)")
            //
            //                print("raw roll data: \(roll)")
            //                print("double roll data: \(dRoll)")
            
            //                var dYawCHEST = Double(yawCHEST)
            //                var dPitchCHEST = Double(pitchCHEST)
            //                var dRollCHEST = Double(rollCHEST)
            //print("MAX \(max)")
            //let normalized = sqrt(dQi * dQi + dQj * dQj + dQk * dQk)
            //                dYaw /= 100.0
            //                dPitch /= 100.0
            //                dRoll /= 100.0
            
            //                print(dYaw)
            //                print(dPitch)
            //                print(dRoll)
            //                dYawCHEST /= 100.0
            //                dPitchCHEST /= 100.0
            //                dRollCHEST /= 100.0
            //                dQi /= BLEController.MAX_VALUE
            //                dQj /= BLEController.MAX_VALUE
            //                dQk /= BLEController.MAX_VALUE
            //                dQs /= BLEController.MAX_VALUE
            //                print("Timestamp: \(timestamp) Qi: \(dQi) Qj: \(dQj) Qk: \(dQk) Qs: \(dQs)")
            //print("Timestamp: \(timestamp) Yaw: \(dYaw) Pitch: \(dPitch) Roll: \(dRoll)")
            //let quaternion = Quaternion(x: dQi, y: dQj, z: dQk, w: dQs)
            //let euler = Utilities.quatToEuler(quat: quaternion)
            //                           let euler = Euler(yaw: sYaw, pitch: sPitch, roll: sRoll)
            ////                print(euler)
//        }
//    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            state = "Bluetooth on this device is powered on."
        case .poweredOff:
            state = "Bluetooth on this device is currently powered off."
        case .unsupported:
            state = "This device does not support Bluetooth Low Energy."
        case .unauthorized:
            state = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:
            state = "The BLE Manager is resetting; a state update is pending."
        case .unknown:
            state = "The state of the BLE Manager is unknown."
        }
    }
    
    func startScan() {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func connect(peripheral: CBPeripheral) {
        stopScan()
        BLEController.shouldAutoconnect = true
        sensorTile = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        
        
    }
    
}

