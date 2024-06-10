//
//  ViewController.swift
//  LoginTest
//
//  Created by 정종원 on 6/5/24.
//

import UIKit
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser
import FirebaseAuth
import FirebaseFirestore


//참조
//https://iosminjae.tistory.com/16
//https://www.youtube.com/watch?v=7Y4UR0UhgHs
//https://velog.io/@beomsoo0/iOS-%EC%B9%B4%EC%B9%B4%EC%98%A4-%EB%A1%9C%EA%B7%B8%EC%9D%B8
//https://velog.io/@app_shawn/IOS-%EC%B9%B4%EC%B9%B4%EC%98%A4-%ED%8C%8C%EC%9D%B4%EC%96%B4%EB%B2%A0%EC%9D%B4%EC%8A%A4-%EB%A1%9C%EA%B7%B8%EC%9D%B8-%EC%97%B0%EB%8F%99-%EA%B5%AC%ED%98%84%ED%95%98%EA%B8%B0
//https://luen.tistory.com/200
// firebase store resion 속도 https://www.gcping.com/

struct User: Codable {
    var name: String
    var email: String
    var profileImageUrl: URL
    var plan: [Plan]
    var friendList: [User]?
}

struct Plan: Codable {
    var uuid: UUID
    var order: Int
    var title: String
    var body: String
    var date: Date
    var time: Date
    var mapInfo: [MapInfo]
    var currentLatitude: Double?
    var currentLongitude: Double?
    var participant: [User]?
}

struct MapInfo: Codable {
    var placeLatitude: Double
    var placeLongitude: Double
    var placeName: String
}


class ViewController: UIViewController {
    
    //firestore
    let db = Firestore.firestore()
    
    private lazy var nickNameLabel: UILabel = {
        var nickNameLabel = UILabel()
        nickNameLabel.translatesAutoresizingMaskIntoConstraints = false
        nickNameLabel.text = "nickNameLabel Default"
        return nickNameLabel
    }()
    
    private lazy var emailLabel: UILabel = {
        var emailLabel = UILabel()
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.text = "emailLabel Default"
        return emailLabel
    }()
    
    private lazy var kakaoLoginButton: UIButton = {
        var kakaoLoginButton = UIButton()
        kakaoLoginButton.translatesAutoresizingMaskIntoConstraints = false
        kakaoLoginButton.setImage(UIImage(named: "kakao_login_medium_narrow"), for: .normal)
        return kakaoLoginButton
    }()
    
    private lazy var kakaoLogoutButton: UIButton = {
        var kakaoLogoutButton = UIButton()
        kakaoLogoutButton.translatesAutoresizingMaskIntoConstraints = false
        kakaoLogoutButton.setTitle("Logout", for: .normal)
        kakaoLogoutButton.setTitleColor(.systemBlue, for: .normal)
        return kakaoLogoutButton
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        kakaoLoginButton.addTarget(self, action: #selector(kakaoLoginButtonTapped), for: .touchUpInside)
        kakaoLogoutButton.addTarget(self, action: #selector(kakaoLogoutButtonTapped), for: .touchUpInside)
        
        view.addSubview(nickNameLabel)
        view.addSubview(emailLabel)
        view.addSubview(kakaoLoginButton)
        view.addSubview(kakaoLogoutButton)
        
        NSLayoutConstraint.activate([
            // nickNameLabel Constraints
            nickNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nickNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nickNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // emailLabel Constraints
            emailLabel.topAnchor.constraint(equalTo: nickNameLabel.bottomAnchor, constant: 20),
            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // kakaoLoginButton Constraints
            kakaoLoginButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 40),
            kakaoLoginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            kakaoLoginButton.widthAnchor.constraint(equalToConstant: 200),
            kakaoLoginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // kakaoLogoutButton Constraints
            kakaoLogoutButton.topAnchor.constraint(equalTo: kakaoLoginButton.bottomAnchor, constant: 20),
            kakaoLogoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            kakaoLogoutButton.widthAnchor.constraint(equalToConstant: 200),
            kakaoLogoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    
    func setUserInfo() {
        UserApi.shared.me {(user, error) in
            if let error = error {
                print("setUserInfo Error: \(error.localizedDescription)")
            } else {
                print("setUserInfo nickname: \(user?.kakaoAccount?.profile?.nickname ?? "no nickname")")
                print("setUserInfo email: \(user?.kakaoAccount?.email ?? "no email")")
                print("setUserInfo profileImageUrl: \(String(describing: user?.kakaoAccount?.profile?.profileImageUrl))")
                
                guard let userId = user?.id else {return}
                
                print("setUserInfo 닉네임 : \(user?.kakaoAccount?.profile?.nickname ?? "no nickname").....이메일 : \(user?.kakaoAccount?.email ?? "no nickname"). . . . .유저 ID : \(userId)")
                self.nickNameLabel.text = "Nickname : \(user?.kakaoAccount?.profile?.nickname ?? "no nickname")"
                self.emailLabel.text = "Email : \(user?.kakaoAccount?.email ?? "no nickname")"
                
                //TODO: - fetchSignInMethods deprecated, 이메일로 확인하는것은 보안에 문제가됨.
                // Firebase에 사용자 등록 전에 이미 가입된 사용자인지 확인
                Auth.auth().fetchSignInMethods(forEmail: user?.kakaoAccount?.email ?? "") { signInMethods, error in
                    if let error = error {
                        print("Error checking email duplication: \(error.localizedDescription)")
                        return
                    }
                    if let signInMethods = signInMethods, !signInMethods.isEmpty {
                        // 이미 사용자가 존재하는 경우 로그인 시도
                        Auth.auth().signIn(withEmail: (user?.kakaoAccount?.email)!,
                                           password: "\(String(describing: user?.id))"
                        ) { authResult, error in
                            if let error = error {
                                print("FB: 이미 사용자가 존재하는 경우 로그인 시도 signin failed error: \(error.localizedDescription)")
                            } else {
                                print("FB: 이미 사용자가 존재하는 경우 로그인 시도 signin success")
                            }
                        }
                    } else {
                        // 새로운 사용자 생성
                        Auth.auth().createUser(withEmail: (user?.kakaoAccount?.email)!,
                                               password: "\(String(describing: user?.id))"
                        ) { authResult, error in
                            if let error = error as NSError?, error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                                // 이메일이 이미 사용 중일 때, 로그인 시도
                                Auth.auth().signIn(withEmail: (user?.kakaoAccount?.email)!,
                                                   password: "\(String(describing: user?.id))"
                                ) { authResult, error in
                                    if let error = error {
                                        print("FB: 이메일이 이미 사용 중일 때, 로그인 시도 signin failed error: \(error.localizedDescription)")
                                    } else {
                                        print("FB: 이메일이 이미 사용 중일 때, 로그인 시도 signin success")
                                    }
                                }
                            } else if let error = error {
                                print("FB: 이메일이 사용중이지 않을때 signup failed error: \(error.localizedDescription)")
                            } else {
                                print("FB: 이메일이 사용중이지 않을때 signup success")
                            }
                        }
                    }
                }
            }
            let nickname = user?.kakaoAccount?.profile?.nickname ?? "no nickname"
            let email = user?.kakaoAccount?.email ?? "no email"
            let profileImageUrl = user?.kakaoAccount?.profile?.profileImageUrl
            let userId = user?.id
            let user = User(name: nickname, email: email, profileImageUrl: profileImageUrl!, plan: [], friendList: [])
                            
            // Firestore에 사용자 정보 저장
            self.saveUserToFirestore(user: user, userId: String(userId!))
        }
    }
    
    //MARK: - Login/out Methods
    @objc func kakaoLoginButtonTapped() {
        print("Kakao Login Button Tapped")
        // 카카오 토큰이 존재한다면
        if AuthApi.hasToken() {
            UserApi.shared.accessTokenInfo { accessTokenInfo, error in
                if let error = error {
                    print("DEBUG: 카카오톡 토큰 가져오기 에러 \(error.localizedDescription)")
                    self.kakaoLogin()
                } else {
                    // 토큰 유효성 체크 성공 (필요 시 토큰 갱신됨)
                    print("토큰이 있음: \(String(describing: accessTokenInfo))")
                    self.setUserInfo()
                }
            }
        } else {
            // 토큰이 없는 상태 로그인 필요
            self.kakaoLogin()
            print("토큰이 없는 상태")
        }
    }
    
    func kakaoLogin() {
        if UserApi.isKakaoTalkLoginAvailable() { //카카오톡 앱이 있는경우 loginWithKakaoTalk
            UserApi.shared.loginWithKakaoTalk { (oauthToken, error) in
                if let error = error {
                    print("Error during KakaoTalk login: \(error.localizedDescription)")
                } else {
                    print("loginWithKakaoTalk() success.")
                    self.setUserInfo()
                }
            }
        } else { //카카오톡이 설치되어 있지 않은 경우 웹으로 연결 loginWithKakaoAccount
            UserApi.shared.loginWithKakaoAccount { (oauthToken, error) in
                if let error = error {
                    print("Error during web login: \(error.localizedDescription)")
                } else {
                    print("loginWithKakaoAccount() success.")
                    self.setUserInfo()
                }
            }
        }
    }
    
    @objc func kakaoLogoutButtonTapped() {
        //kakaoLogout
        UserApi.shared.logout{(error) in
            if let error = error {
                print(error)
            } else {
                print("kakao logout success")
                self.nickNameLabel.text = "Logout: Default Nickname"
                self.emailLabel.text = "Logout: Default Email"
            }
        }
        
        //firebase logout
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            print("firebase logout success")
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError)")
        }
    }
    
    //MARK: - FireStore Methods
    
    func saveUserToFirestore(user: User, userId: String) {
        let userRef = db.collection("users").document(userId)
        do {
            try userRef.setData(from: user)
        } catch let error {
            print("Error writing user to Firestore: \(error)")
        }
    }
    
    func fetchUserFromFirestore(userId: String, completion: @escaping (User?) -> Void) {
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                do {
                    let user = try document.data(as: User.self)
                    completion(user)
                } catch let error {
                    print("Error decoding user: \(error)")
                    completion(nil)
                }
            } else {
                print("User does not exist in Firestore")
                completion(nil)
            }
        }
    }
    
    
}

