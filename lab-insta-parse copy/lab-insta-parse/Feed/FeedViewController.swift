//
//  FeedViewController.swift
//  lab-insta-parse
//
//  Created by Charlie Hieger on 11/1/22.
//

import UIKit
import ParseSwift

class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()

    private var posts = [Post]() {
        didSet {
            // Reload table view data any time the posts variable gets updated.
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true

        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(onPullToRefresh), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        queryPosts()
    }

    private func queryPosts(completion: (() -> Void)? = nil) {
        // Get the date for yesterday.
        let yesterdayDate = Calendar.current.date(byAdding: .day, value: (-1), to: Date())!
        
        let query = Post.query()
            .include("user")
            .include("comments")  // Include comments in the query
            .include("comments.user")  // Include the user of each comment
            .order([.descending("createdAt")])
            .where("createdAt" >= yesterdayDate)
            .limit(10)

        query.find { [weak self] result in
            switch result {
            case .success(let posts):
                self?.posts = posts
            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
            }

            completion?()
        }
    }

    @IBAction func onLogOutTapped(_ sender: Any) {
        let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ["postReminder"])
        showConfirmLogoutAlert()
    }

    @objc private func onPullToRefresh() {
        refreshControl.beginRefreshing()
        queryPosts { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of \(User.current?.username ?? "current account")?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let post = posts[section]
        let comments = post.comments
        
        return (comments?.count ?? 0) + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            guard let postCell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as?
                    PostCell
            else {
                return UITableViewCell()
            }
            postCell.configure(with: posts[indexPath.section])
            return postCell
            
        } else{
            guard let commentCell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as?
                    CommentCell
            else{
                return UITableViewCell()
            }
            let post = posts[indexPath.section]
            let comments = post.comments ?? []
            
            if (comments.count > 0){
                let comment = comments[indexPath.row-1]
                commentCell.nameLabel.text = comment.user?.username
                commentCell.commentLabel.text = comment.text
            }
            
            return commentCell
        }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.row]
        
                var comment = Comment()
                comment.text = "The view looks amazing!"
                comment.post = post
        comment.user = User.current
     
        
                // Save asynchronously (preferred way) - Performs work on background queue and returns to specified callbackQueue.
                // If no callbackQueue is specified it returns to main queue.
                comment.save { result in
                    switch result {
                    case .success(let savedComment):
                        print("Comment Saved Sucessfully")
                        
                        var updatedPost = post
                        
                        if updatedPost.comments == nil {
                            updatedPost.comments = []
                        }
                        
                        updatedPost.comments?.append(savedComment)
                        
                        updatedPost.save { result in
                            switch result {
                            case.success(let savedPost):
                                print("Post updated with new comment: \(savedPost)")
                            case.failure(let error):
                                print("Error saving post with comment: \(error)")
                            }
                        }
                    case .failure(let error):
                        assertionFailure("Error saving comment: \(error)")
                    }
                }
    }
}
extension FeedViewController: UITableViewDelegate { }
extension FeedViewController {
    func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: description ?? "Please try again...", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}
