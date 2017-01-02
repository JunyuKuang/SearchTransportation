//
//  StationTableViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 12/31/16.
//  Copyright © 2016 Jonny. All rights reserved.
//

import UIKit

class StationTableViewController: TableViewController {
    
    private(set) var busStations = [BusStation]()
    
    private(set) var searchedBusStations = [BusStation]()
    
    var excludedStations = Set<BusStation>()
    
    override var hintForEmptyTable: String {
        return "No Stations"
    }
    
    override var searchBarPlaceholder: String? {
        return "Stations, Routes"
    }
    
    override var isSearchable: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(busStationsDidChange), name: .busStationsDidChange, object: nil)
        busStationsDidChange()
    }
    
    func busStationsDidChange() {
        
        if excludedStations.isEmpty {
            busStations = BusStation.activeStations.sorted { $0.name < $1.name }
        } else {
            busStations = BusStation.activeStations.filter { !excludedStations.contains($0) } .sorted { $0.name < $1.name }
        }
        
        if searchController.isActive {
            updateSearchResults(for: searchController)
        } else {
            tableView.reloadData()
        }
    }
    
    override func updateSearchResults(for searchController: UISearchController) {
        super.updateSearchResults(for: searchController)
        
        if searchController.isActive {
            let searchText = searchController.searchBar.text ?? ""
            
            if searchText.isEmpty {
                searchedBusStations = busStations
            } else {
                let routes = BusRoute.activeRoutes.filter { $0.name.range(of: searchText, options: .caseInsensitive) != nil }
                searchedBusStations = busStations.filter { station -> Bool in
                    station.name.range(of: searchText, options: .caseInsensitive) != nil || routes.contains { route -> Bool in route.stationSet.contains(station) }
                }
            }
        } else {
            searchedBusStations.removeAll()
        }
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let count = searchController.isActive ? searchedBusStations.count : busStations.count
        hintLabel.isHidden = count > 0
        return count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Subtitle", for: indexPath)
        let busStation = searchController.isActive ? searchedBusStations[indexPath.row] : busStations[indexPath.row]
        
        cell.textLabel?.text = busStation.name
        cell.detailTextLabel?.text = BusRoute.activeRoutes.filter { $0.stationSet.contains(busStation) } .map { $0.name } .joined(separator: ", ")
        
        return cell
    }
    
//    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
//        
//    }
    
}

