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

var calibrate_flag = 0

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

func Endian_change(org:UInt32) -> UInt32 {
    var org2=org
    var new:UInt32=0
    for _ in 1...4 {
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
               // nc.post(name:Notification.Name(rawValue:"DeviceFound"), object: peripheral)
        if let name = peripheral.name {
            print("NAME:")
            print("\(name)")
            //            if name == "YostLabsMBLE" {
            if name == "SLAVE"{
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
                
                let setstream:[UInt8] = [0x3a, 0x38, 0x30, 0x2c, 0x31, 0x2c, 0x31, 0x2c, 0x32, 0x35, 0x35, 0x2c, 0x32, 0x35, 0x35, 0x2c, 0x32, 0x35, 0x35, 0x2c, 0x32, 0x35, 0x35, 0x2c, 0x32, 0x35, 0x35, 0x5c, 0x6e]
                _ = Data(bytes: setstream)
                
                let startbin:[UInt8] = [0xf9, 0x55, 0x55];
                let startbinbyte = Data(bytes: startbin)
                
                let setheader:[UInt8] = [0xf7,0xdd,0x00,0x00,0x00,0x50,0x2d]
                let setheaderbyte = Data(bytes:setheader)
                
                let cali:[UInt8] = [0xFD,0xFC]
                let calibyte = Data(bytes: cali)
                
                
                //peripheral.writeValue(setstreambyte, for: characteristic,type: CBCharacteristicWriteType.withoutResponse)
                
                peripheral.writeValue(setheaderbyte, for: characteristic,type: CBCharacteristicWriteType.withoutResponse)
                
                peripheral.writeValue(startbinbyte, for: characteristic,type: CBCharacteristicWriteType.withoutResponse)
                
                if (calibrate_flag == 1){
                    peripheral.writeValue(calibyte, for: characteristic,type: CBCharacteristicWriteType.withoutResponse)
                    calibrate_flag = 0
                }
                
                
                print(peripheral)
                print(characteristic)
                print(service)
                
                peripheral.setNotifyValue(true, for: characteristic)
                
                return
            }
        }
    }
    
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if let value = characteristic.value {
            //let data = NSMutableData(data: value)
            //data_packet.appendData(data)
            data_string=Data()
            data_string.append(value)
            let sensor_1_header:UInt32=0xFE;
            let sensor_2_header:UInt32=0xFF;
            var raw:UInt32=0
            var sensor_id:UInt32=0
            var hex_string=""
//            var timestamp:Float=0;
            var counter:Int=0;
            var yaw:Float=0;
            var pitch:Float=0;
            var roll:Float=0;
            var droll:Double=0;
            var dpitch:Double=0;
            var dyaw:Double=0;
            let packet_size:UInt8 = 13
            let data = NSMutableData(data: data_string);
            let packages_caught:UInt8 = UInt8(data_string.count) / packet_size
            let valid_packet=(UInt8(data_string.count) % packet_size)
            //print("data from teensy/yost = ", data,"Valid packet =",valid_packet)
            if(valid_packet==0)
            {
                for _ in 0..<packages_caught{
                    data.getBytes(&sensor_id, range: NSMakeRange(counter,1))
                    counter+=1
                    data.getBytes(&raw, range: NSMakeRange(counter,4))
                    raw=Endian_change(org:raw)
                    hex_string=String(format:"%02X",raw)
                    //print("pitch raw = ", hex_string)
                    pitch = hextoFloat(data_string:hex_string)
                    counter+=4
                    data.getBytes(&raw, range: NSMakeRange(counter,4))
                    raw=Endian_change(org:raw)
                    hex_string=String(format:"%02X",raw)
                    //print("yaw raw = ", hex_string)
                    yaw = hextoFloat(data_string:hex_string)
                    counter+=4
                    data.getBytes(&raw, range: NSMakeRange(counter,4))
                    raw=Endian_change(org:raw)
                    hex_string=String(format:"%02X",raw)
                    //print("roll raw = ", hex_string)
                    roll = hextoFloat(data_string:hex_string)//string to float
                    counter+=4
                    dyaw = (Double)(yaw*180/3.14159265)//convert radians to degrees
                    droll = (Double)(roll*180/3.14159265)
                    dpitch = (Double)(pitch*180/3.14159265)
                    
                    //                print("Euler Angles: yaw: \(dyaw) pitch: \(droll) roll: \(dpitch)")
                    
                    
                    //                if (dyaw < 0){
                    //                    dyaw = dyaw+360
                    //                }
                    //                if (droll < 0){
                    //                    droll = droll+360
                    //                }
                    //                if (dpitch < 0){
                    //                    dpitch = dpitch+360
                    //                }
                    
                    let euler = Euler(yaw: dyaw, pitch: dpitch, roll: droll);
                    //                print("Euler Angles: yaw: \(euler.yaw) pitch: \(euler.pitch) roll: \(euler.roll)")
                    
                    let nc = NotificationCenter.default
                    ////                nc.post(name:Notification.Name(rawValue:"DeviceDataCHEST"), object: eulerCHEST)
                    //print("sensor_id=",sensor_id)
                    if(sensor_id==sensor_1_header)
                    {
                        //print("Sensor 1")
                        nc.post(name:Notification.Name(rawValue:"Sensor_1"), object: euler)
                    }
                    else if(sensor_id==sensor_2_header)
                    {
                        //print("Sensor 2")
                        nc.post(name:Notification.Name(rawValue:"Sensor_2"), object: euler)
                    }
                }
            }
            //print("packages caught = ",packages_caught)
        }
    }
    
    
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

