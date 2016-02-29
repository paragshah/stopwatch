//
//  StopWatchViewController.swift
//  StopWatch
//
//  Created by Parag Shah on 2/25/16.
//  Copyright © 2016 Parag Shah. All rights reserved.
//

import UIKit

/*!
A simple stopwatch app that mimics the native StopWatch on iOS.

Note: there are multiple ways that a stop watch may be implemented here. I chose to go with using CADisplayLink because it was the most accurate in staying in sync. Other ways included using NSTimer with a .01 time interval (too slow) or using elapsed time via NSDate and timeIntervalSinceReferenceDate, but the pause functionality was not possible.
*/
class StopWatchViewController: UIViewController {

    @IBOutlet weak var lapResetButton: UIButton!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var mainMinutesLabel: UILabel!
    @IBOutlet weak var mainSecondsLabel: UILabel!
    @IBOutlet weak var mainMillisecondsLabel: UILabel!
    @IBOutlet weak var actionView: UIView!
    @IBOutlet weak var lapMinutesLabel: UILabel!
    @IBOutlet weak var lapSecondsLabel: UILabel!
    @IBOutlet weak var lapMillisecondsLabel: UILabel!
    @IBOutlet weak var lapTableView: UITableView!

    // Constants
    let emptyTimestamp = (0.0, 0.0, 0.0)
    let lightGrayColor = UIColor(red: 239/255.0, green: 239/255.0, blue: 244/255.0, alpha: 1.0)
    let darkGrayColor = UIColor(red: 142/255.0, green: 142/255.0, blue: 147/255.0, alpha: 1.0)
    let greenColor = UIColor(red: 72/255.0, green: 217/255.0, blue: 97/255.0, alpha: 1.0)
    let redColor = UIColor(red: 1.0, green: 59/255.0, blue: 48/255.0, alpha: 1.0)

    // Vars
    lazy var displayLink: CADisplayLink = {
        return CADisplayLink(target: self, selector: "displayLinkUpdated:")
    }()

    var mainDisplayLinkTimeStamp: CFTimeInterval = 0.0
    var lapDisplayLinkTimeStamp: CFTimeInterval = 0.0
    var lapList: [(minutes: Double, seconds: Double, milliseconds: Double)] = []

    enum TimeType {
        case Main
        case Lap
    }

    enum ActionState {
        case Lap
        case Start
        case Stop
        case Reset
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: "StopWatchViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // round buttons
        lapResetButton.layer.cornerRadius = 32
        startStopButton.layer.cornerRadius = 32

        actionView.backgroundColor = lightGrayColor

        // setup table view
        lapTableView.backgroundColor = lightGrayColor
        lapTableView.registerClass(LapCell.self, forCellReuseIdentifier: "cell")

        displayLink.paused = true;
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }

    @IBAction func lapResetButtonTapped(sender: AnyObject) {
        if displayLink.paused {
            reset()
        } else {
            lap()
        }
    }

    @IBAction func startStopButtonTapped(sender: AnyObject) {
        displayLink.paused = !displayLink.paused

        if displayLink.paused {
            stop()
        } else {
            start()
        }
    }

    func stop() {
        updateUIForState(.Stop)
    }

    func start() {
        updateUIForState(.Start)
    }

    func lap() {
        // add new lap to array
        let lapTimestamp = computeFromDisplayLinkTimestamp(lapDisplayLinkTimeStamp)
        lapList.insert(lapTimestamp, atIndex: 0)

        // reset the lap display link timestamp so it will start over
        lapDisplayLinkTimeStamp = 0.0

        updateUIForState(.Lap)
    }

    func reset() {
        // update display link
        displayLink.paused = true;
        mainDisplayLinkTimeStamp = 0.0
        lapDisplayLinkTimeStamp = 0.0

        // update model
        lapList.removeAll()

        updateUIForState(.Reset)
    }

    func displayLinkUpdated(sender: CADisplayLink) {
        setTimeForType(.Main)
        setTimeForType(.Lap)
    }

    func setTimeForType(type: TimeType) {
        if type == .Main {
            mainDisplayLinkTimeStamp += displayLink.duration
        } else {
            lapDisplayLinkTimeStamp += displayLink.duration
        }

        let displayLinkTimeStamp = type == .Main ? mainDisplayLinkTimeStamp : lapDisplayLinkTimeStamp
        let timestampParts = computeFromDisplayLinkTimestamp(displayLinkTimeStamp)

        updateTimeLabelsForType(type, timestamp: timestampParts)
    }

    func updateTimeLabelsForType(type: TimeType, timestamp: (minutes: Double, seconds: Double, milliseconds: Double)) {
        let minutesString = String(format: "%02d", Int(timestamp.minutes))
        let secondsString = String(format: "%02d", Int(timestamp.seconds))
        let millisecondsString = String(format: "%02d", Int(timestamp.milliseconds))

        switch type {
        case .Main:
            mainMinutesLabel.text = minutesString
            mainSecondsLabel.text = secondsString
            mainMillisecondsLabel.text = millisecondsString

        case .Lap:
            lapMinutesLabel.text = minutesString
            lapSecondsLabel.text = secondsString
            lapMillisecondsLabel.text = millisecondsString
        }
    }

    func updateUIForState(actionState: ActionState) {
        switch actionState {
        case .Lap:
            // UI
            updateTimeLabelsForType(.Lap, timestamp: emptyTimestamp)

            // update table view; NOTE: it is assumed a new entry has been added to the array before this gets called
            lapTableView.beginUpdates()
            lapTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
            lapTableView.endUpdates()

        case .Start:
            lapResetButton.enabled = true
            lapResetButton.setTitle("Lap", forState: .Normal)
            startStopButton.setTitle("Stop", forState: .Normal)
            startStopButton.setTitleColor(redColor, forState: .Normal)

        case .Stop:
            lapResetButton.setTitle("Reset", forState: .Normal)
            startStopButton.setTitle("Start", forState: .Normal)
            startStopButton.setTitleColor(greenColor, forState: .Normal)

        case .Reset:
            // UI
            lapResetButton.setTitle("Lap", forState: .Normal)
            lapResetButton.enabled = false
            updateTimeLabelsForType(.Main, timestamp: emptyTimestamp)
            updateTimeLabelsForType(.Lap, timestamp: emptyTimestamp)

            // update table view; NOTE: it is assumed the array has been cleared before this gets called
            lapTableView.reloadData()
        }
    }

    func computeFromDisplayLinkTimestamp(timestamp: CFTimeInterval) -> (minutes: Double, seconds: Double, milliseconds: Double) {
        let minutes = floor(timestamp / 60)
        let num = timestamp - minutes * 60
        let seconds = floor(num)
        let milliseconds = floor((num - seconds) * 100)

        return (minutes, seconds, milliseconds)
    }
}

// MARK: UITableView

extension StopWatchViewController: UITableViewDelegate {
}

extension StopWatchViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lapList.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! LapCell
        cell.backgroundColor = lightGrayColor
        cell.textLabel?.text = "Lap \(lapList.count - indexPath.row)"
        cell.textLabel?.textColor = darkGrayColor
        cell.textLabel?.font = UIFont.systemFontOfSize(13.0)

        let timestamp = lapList[indexPath.row]
        let minutesString = String(format: "%02d", Int(timestamp.minutes))
        let secondsString = String(format: "%02d", Int(timestamp.seconds))
        let millisecondsString = String(format: "%02d", Int(timestamp.milliseconds))

        cell.detailTextLabel?.text = "\(minutesString):\(secondsString).\(millisecondsString)"
        cell.detailTextLabel?.textColor = UIColor.blackColor()
        cell.detailTextLabel?.font = UIFont(name: lapMinutesLabel.font.fontName, size: 16.0)
        return cell
    }
}

private class LapCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }

    private override func prepareForReuse() {
        super.prepareForReuse()

        textLabel?.text = nil
        accessoryType = .None
        accessoryView = nil
        detailTextLabel?.text = nil
    }
}
