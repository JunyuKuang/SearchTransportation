//
//  SelectEndStationTableViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 1/1/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

import UIKit

class SelectEndStationTableViewController: StationTableViewController {
    
    var startStation: BusStation?
    
    override func viewDidLoad() {
        if let startStation = startStation {
            excludedStations.insert(startStation)
        }
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let routeSearchTableViewController = segue.destination as? RouteSearchTableViewController,
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell)
            else { return }
        
        routeSearchTableViewController.startStation = startStation
        routeSearchTableViewController.endStation = searchController.isActive ? searchedBusStations[indexPath.row] : busStations[indexPath.row]
        
        super.prepare(for: segue, sender: sender)
    }
    
}
