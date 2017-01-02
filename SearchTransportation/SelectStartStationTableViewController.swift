//
//  RouteAddStationsTableViewController.swift
//  SearchTransportation
//
//  Created by Jonny on 1/1/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

import UIKit

class SelectStartStationTableViewController: StationTableViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let selectEndStationTableViewController = segue.destination as? SelectEndStationTableViewController,
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell)
            else { return }
        
        selectEndStationTableViewController.startStation = searchController.isActive ? searchedBusStations[indexPath.row] : busStations[indexPath.row]
        
        super.prepare(for: segue, sender: sender)
    }
    
}

