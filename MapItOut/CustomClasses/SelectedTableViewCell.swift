//
//  SelectedTableViewCell.swift
//  MapItOut
//
//  Created by Portia Wang on 7/14/17.
//  Copyright © 2017 Portia Wang. All rights reserved.
//

import UIKit

class SelectedTableViewCell: UITableViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var relationshipLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var contactButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contactButton.layer.cornerRadius = 15
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
