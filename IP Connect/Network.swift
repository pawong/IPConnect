//
//  Network.swift
//  IP Connect
//
//  Created by Paul Wong on 3/26/18.
//  Copyright © 2018 Mazookie, LLC. All rights reserved.
//

import Foundation
import Cocoa
import SystemConfiguration


class Network {

    var externalIP: String = "N/A"
    var priorIP: String = "None"

    var hasIpChanged: Bool = true

    func getHasIpChanged() -> Bool {
        return hasIpChanged
    }

    func setHasIpChanged(_ value: Bool) {
        hasIpChanged = value
    }

    func getExternalIP() -> String {
        getPublicIPNoWait()
        return externalIP
    }

    func parseIP(_ message:String) -> String {
        var newIP: String = ""
        do {
            let pattern = #"\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b"#
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let results = regex.firstMatch(in: message, options: [], range: NSRange(message.startIndex..<message.endIndex, in: message))

            results.map {
                newIP = String(message[Range($0.range, in: message)!])
            }
        }
        catch {
            print("Unable to parse IP address.")
        }
    
        return newIP
    }
    
    func updatePublicIP(_ message:String) {
        let newIP = parseIP(message)
        if !newIP.isEmpty && priorIP != newIP {
            externalIP = newIP
            History.append(externalIP + ", " + priorIP)
            priorIP = newIP
            hasIpChanged = true
        }
    }
    
    func getPublicIPWait() {
        let url = URL(string: "https://api.ipify.org/")
        do {
            let message = try String(contentsOf: url!, encoding: String.Encoding.utf8)
            updatePublicIP(message)
        } catch {
            print("Unable to get external IP from getPublicIPWait.")
            externalIP = "N/A"
            priorIP = externalIP
        }
    }

    func getPublicIPNoWait() {
        guard let downloadURL = URL(string: "https://api.ipify.org/") else { return }

        URLSession.shared.dataTask(with: downloadURL) { data, urlResponse, error in

            guard let data = data, error == nil, urlResponse != nil else {
                print("Unable to get external IP from getPublicIPNoWait.")
                self.externalIP = "N/A"
                self.priorIP = self.externalIP
                return
            }

            let message = String(data: data, encoding: .utf8)!
            self.updatePublicIP(message)
        }.resume()
    }

    func getInterfaceType(_ find_name:String) -> String {
        let interfaces = SCNetworkInterfaceCopyAll() as NSArray
        for interface in interfaces {
            if let name = SCNetworkInterfaceGetBSDName(interface as! SCNetworkInterface) {
                if name as String == find_name {
                    let type = SCNetworkInterfaceGetLocalizedDisplayName(interface as! SCNetworkInterface)
                    return type! as String
                }
            }
        }

        return ""
    }

    func getMacAddress(_ find_name:String) -> String {
        let interfaces = SCNetworkInterfaceCopyAll() as NSArray
        for interface in interfaces {
            if let name = SCNetworkInterfaceGetBSDName(interface as! SCNetworkInterface) {
                if name as String == find_name {
                    let type = SCNetworkInterfaceGetHardwareAddressString(interface as! SCNetworkInterface)
                    return type! as String
                }
            }
        }

        return ""
    }

    func getIFAddresses(_ includeIP6: Bool) -> [[String:String]] {
        var interfaces = [[String:String]]()

        // Get list of all interfaces on the local machine:
        var ifaddr : UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return interfaces }
        guard let firstAddr = ifaddr else { return interfaces }

        // For each interface ...
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee

            // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) || (addr.sa_family == UInt8(AF_INET6) && includeIP6) {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if (getnameinfo(
                        ptr.pointee.ifa_addr,
                        socklen_t(addr.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST
                        ) == 0) {
                        var interface = [String: String]()
                        interface["name"] = String(cString: ptr.pointee.ifa_name)
                        interface["ip_address"] = String(cString: hostname)
                        interface["type"] = getInterfaceType(interface["name"]!)
                        interface["mac_address"] = getMacAddress(interface["name"]!)
                        interfaces.append(interface)
                    }
                }
            }
        }

        freeifaddrs(ifaddr)
        return interfaces
    }
}
