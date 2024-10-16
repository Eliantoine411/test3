//
//  PostCell.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/3/22.
//

import UIKit
import Alamofire
import AlamofireImage

class PostCell: UITableViewCell {

    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var postImageView: UIImageView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel! // Location label
    @IBOutlet private weak var timeLabel: UILabel! // Timestamp label

    private var imageDataRequest: DataRequest?

    func configure(with post: Post) {
        // Username
        if let user = post.user {
            usernameLabel.text = user.username
        }

        // Image
        if let imageFile = post.imageFile, let imageUrl = imageFile.url {
            imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
                switch response.result {
                case .success(let image):
                    self?.postImageView.image = image
                case .failure(let error):
                    print("❌ Error fetching image: \(error.localizedDescription)")
                }
            }
        }

        // Caption
        captionLabel.text = post.caption

        // Location
        locationLabel.text = post.locationString ?? "No Location String"

        // Date and Time
        if let date = post.timestamp {
            // Format and set date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateLabel.text = dateFormatter.string(from: date)

            // Format and set time
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm" // 24-hour format (use "hh:mm a" for 12-hour format)
            timeLabel.text = timeFormatter.string(from: date)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // TODO: P1 - Cancel image download
        // Reset image view image.
        postImageView.image = nil

        // Cancel image request.
        imageDataRequest?.cancel()

    }
}
