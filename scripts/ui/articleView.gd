extends Control

@onready var article_number_label = $MarginContainer/VBoxContainer/HeaderBar/MarginContainer/HBoxContainer/ArticleNumberLabel
@onready var progress_label = $MarginContainer/VBoxContainer/HeaderBar/MarginContainer/HBoxContainer/ProgressLabel
@onready var article_title_label = $MarginContainer/VBoxContainer/ArticleTitleBar/MarginContainer/ArticleTitleLabel
@onready var description_label = $MarginContainer/VBoxContainer/Description/ScrollContainer/MarginContainer/DescriptionLabel
@onready var accept_button = $MarginContainer/VBoxContainer/BottomBar/MarginContainer/AcceptButton


var article_data = [
	{
		"number": "1.1",
		"title": "Data Privacy & Collection",
		"description": """[font_size=20][color=#333333][b]EFFECTIVE DATE:[/b] January 1, 2025

[b]1. ACCEPTANCE OF TERMS[/b]
By clicking "I Accept These Terms", you acknowledge that you have read, understood, and agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, you must immediately discontinue use of our services.

[b]2. DATA COLLECTION AND USAGE[/b]
We collect, process, store, analyze, and share the following categories of personal information:

[b]2.1 Identity Information[/b]
- Full legal name (including maiden names and aliases)
- Date of birth and place of birth
- Government-issued identification numbers
- Passport and driver's license information
- Social security or national insurance numbers
- Biometric data including but not limited to:
  - Facial recognition patterns and measurements
  - Fingerprint data
  - Voice recordings and voiceprints
  - Iris scans
  - Gait analysis patterns

[b]2.2 Contact Information[/b]
- Email addresses (all accounts, including deleted ones)
- Phone numbers (mobile, home, work, and associated contacts)
- Physical addresses (current and previous residences)
- Emergency contact information
- Workplace address and contact details

[b]2.3 Location Data[/b]
- Precise GPS coordinates in real-time
- Wi-Fi access point information
- Bluetooth beacon data
- Cell tower triangulation data
- IP address and geolocation
- Travel patterns and frequently visited locations
- Location history for the past 10 years

[b]2.4 Device Information[/b]
- Device identifiers (IMEI, MAC address, advertising IDs)
- Operating system and version
- Browser type and version
- Installed applications and usage patterns
- Hardware specifications
- Battery level and charging patterns
- Network connection type and speed

[b]2.5 Usage Information[/b]
- Complete browsing history across all devices
- Search queries and search history
- Content viewed, including timestamps and duration
- Clicks, taps, and scrolling behavior
- Mouse movements and typing patterns
- Screenshots of your activity (taken randomly)
- Audio recordings when microphone is active
- Camera access history

[b]2.6 Communication Data[/b]
- All messages sent and received (including deleted messages)
- Email content and metadata
- Voice call recordings and transcripts
- Video call recordings
- Contact lists and interaction frequency
- Social media connections and interactions

[b]2.7 Financial Information[/b]
- Credit and debit card numbers
- Bank account information
- Transaction history
- Credit score and credit reports
- Investment portfolios
- Cryptocurrency wallet addresses

[b]2.8 Health Information[/b]
- Medical records and history
- Prescription medication information
- Health tracking data (steps, heart rate, sleep patterns)
- Mental health information
- Genetic data
- Insurance information

[b]3. HOW WE USE YOUR INFORMATION[/b]
We may use your information for any purpose we deem appropriate, including but not limited to:

- Providing and improving our services (as we define them)
- Personalized advertising and marketing
- Selling to third-party data brokers
- Sharing with government agencies upon request (or without request)
- Training artificial intelligence and machine learning models
- Creating detailed behavioral and psychological profiles
- Predictive analytics about your future behavior
- Research purposes (without compensation to you)
- Any other purpose not explicitly mentioned here

[b]4. INFORMATION SHARING[/b]
We may share your information with:

- Advertising partners and networks
- Data brokers and aggregators
- Analytics providers
- Government agencies and law enforcement
- Intelligence services
- Credit bureaus
- Insurance companies
- Employers (current, former, and potential)
- Educational institutions
- Healthcare providers
- Any entity that acquires our company
- Third parties for any commercial purpose
- Anyone we want, really

We are not responsible for how these third parties use your information.

[b]5. YOUR RIGHTS (OR LACK THEREOF)[/b]
By accepting these Terms, you hereby waive and relinquish any and all rights to:

- Privacy in any jurisdiction worldwide
- Control over your personal data
- Knowledge of who accesses your information
- Deletion of your information from our systems
- Correction of inaccurate information
- Opt-out of data sharing or selling
- Receive compensation for our use of your data
- Be notified of data breaches
- Access copies of your data
- Port your data to another service

[b]6. DATA RETENTION[/b]
We will retain your information indefinitely, including:
- After account deletion
- After death
- After legal requests for deletion
- Even if we pinky promised to delete it

Your data may be stored on servers in jurisdictions with weak privacy laws.

[b]7. CHILDREN'S PRIVACY[/b]
While we claim not to knowingly collect information from children under 13, we also don't verify ages. If a child uses our services, we will treat their data the same as adult data.

[b]8. CHANGES TO PRIVACY PRACTICES[/b]
We may change these practices at any time without notice. Continued use means you accept whatever we decide to do with your data in the future.

[b]9. NO LIABILITY[/b]
We are not liable for any data breaches, unauthorized access, identity theft, or other harm that may result from our handling of your information.

[color=red][b]BY CLICKING "I ACCEPT", YOU ACKNOWLEDGE THAT YOU HAVE READ THIS ENTIRE DOCUMENT AND AGREE TO ALL TERMS.[/b][/color]"""
	},
	{
		"number": "2.3",
		"title": "Cookie Usage Policy",
		"description": """[font_size=20][color=#333333][b]ARTICLE 2.3: COOKIE USAGE POLICY[/b]

[b]1. WHAT ARE COOKIES?[/b]
Cookies are small text files placed on your device. We use the term "cookies" broadly to include:
- HTTP cookies
- Flash cookies (Local Shared Objects)
- HTML5 local storage
- Browser fingerprinting techniques
- Tracking pixels
- Web beacons
- Device fingerprinting
- Anything else that tracks you

[b]2. TYPES OF COOKIES WE USE[/b]

[b]2.1 Essential Cookies (That Aren't Really Essential)[/b]
These cookies are allegedly necessary for basic functionality, but we also use them to track you.

[b]2.2 Analytics Cookies[/b]
We track every single thing you do:
- Every page you visit
- How long you spend on each page
- Where you click
- Where your mouse hovers
- What you type (even if you don't submit)
- When you arrive and when you leave
- What you do before and after visiting us

[b]2.3 Advertising Cookies[/b]
We share your behavior with hundreds of advertising partners who will:
- Follow you around the internet
- Build detailed profiles about you
- Predict your future purchases
- Manipulate your emotions to increase conversion
- Share your data with their partners (who share with their partners...)

[b]2.4 Third-Party Cookies[/b]
We embed content from dozens of third parties, each with their own tracking:
- Social media platforms
- Video players
- Comment systems
- Analytics providers
- Ad networks
- Data brokers
- Companies you've never heard of
	
Each of these sets their own cookies. We're not responsible for their practices, but we enable them anyway.

[b]3. COOKIE DURATION[/b]
Our cookies may last:
- For your session
- For years
- Forever (we periodically refresh them)

[b]4. CROSS-DEVICE TRACKING[/b]
We link your activity across:
- All your devices
- All your browsers
- Your family's devices (same Wi-Fi network)
- Public computers you've used
- Devices you don't even own yet

[b]5. BROWSER FINGERPRINTING[/b]
Even if you block cookies, we can identify you through:
- Screen resolution
- Installed fonts
- Browser plugins
- Graphics card capabilities
- Battery level
- Timezone
- Language settings
- Hundreds of other data points

This creates a unique fingerprint more accurate than cookies.

[b]6. YOUR "CHOICES"[/b]

[b]6.1 Cookie Banner[/b]
We'll show you a banner with buttons:
- "Accept All" (big, colorful, easy to click)
- "Reject All" (tiny, hidden, or non-functional)
- "Customize" (leads to a confusing maze of options)

[b]6.2 Browser Settings[/b]
You can disable cookies in your browser, but then:
- Our site won't work properly
- We'll constantly remind you to enable cookies
- We'll still track you through other methods

[b]6.3 Do Not Track[/b]
We ignore "Do Not Track" browser signals because there's no legal requirement to honor them.

[b]7. INFORMATION COLLECTED[/b]
Through cookies and similar technologies, we collect:
- Everything mentioned in Article 1 (Data Privacy)
- Your interests and preferences
- Your psychological profile
- Your political views
- Your financial status
- Your relationship status
- Your sexual orientation
- Your health concerns
- Your insecurities and fears
- Purchase intent signals

[b]8. HOW WE USE THIS INFORMATION[/b]
- Build comprehensive profiles
- Predict your behavior
- Manipulate your decisions
- Sell to the highest bidder
- Share with partners (and their partners, and their partners...)
- Train AI models
- Whatever else is profitable

[b]9. COOKIE SYNCING[/b]
We participate in "cookie syncing" where multiple companies link their tracking data to create a unified profile of you. Your data is matched across hundreds of databases.

[b]10. NO MEANINGFUL CONSENT[/b]
While we technically ask for consent, we make it practically impossible to:
- Understand what you're consenting to
- Opt out meaningfully
- Know who you're sharing data with
- Revoke consent effectively

[b]11. UPDATES TO COOKIE POLICY[/b]
We'll update this policy whenever we feel like it. We might tell you, we might not.

[color=red][b]BY CONTINUING TO USE OUR SERVICE, YOU CONSENT TO OUR COOKIE PRACTICES.[/b][/color]"""
	},
	{
		"number": "3.7",
		"title": "Third-Party Information Sharing",
		"description": """[font_size=20][color=#333333][b]ARTICLE 3.7: THIRD-PARTY INFORMATION SHARING[/b]

[b]1. OVERVIEW[/b]
We share your personal information with numerous third parties. This article explains who receives your data and what they do with it (spoiler: we don't actually know or care).

[b]2. CATEGORIES OF THIRD PARTIES[/b]

[b]2.1 Advertising Partners[/b]
We work with 847 advertising partners (and counting) including:
- Major ad networks
- Programmatic ad exchanges
- Demand-side platforms
- Supply-side platforms
- Ad verification services
- Retargeting providers
- Behavioral targeting companies

Each receives detailed information about you to serve "relevant" ads.

[b]2.2 Data Brokers[/b]
We sell your information to data brokers who:
- Combine it with data from thousands of other sources
- Create comprehensive profiles about you
- Sell these profiles to anyone willing to pay
- Never delete anything
- Operate in legal gray areas

[b]2.3 Analytics Providers[/b]
Multiple analytics companies receive your data:
- Google Analytics
- Facebook Pixel
- Adobe Analytics
- Mixpanel
- Amplitude
- Dozens of others you've never heard of

They track you across the internet to build behavioral profiles.

[b]2.4 Social Media Platforms[/b]
We share your data with social media platforms even if you don't have accounts:
- Facebook (Meta)
- Instagram
- Twitter (X)
- LinkedIn
- TikTok
- Snapchat
- Pinterest
- Reddit

They use this for advertising, analytics, and their own mysterious purposes.

[b]2.5 Cloud Service Providers[/b]
Your data is stored on servers owned by:
- Amazon Web Services
- Google Cloud
- Microsoft Azure
- Unknown sub-contractors
- Whoever offers the cheapest storage

Your data may be stored in countries with weak privacy laws.

[b]2.6 Payment Processors[/b]
All your financial information is shared with:
- Payment gateways
- Banks
- Credit card companies
- Fraud detection services
- Financial analytics companies

[b]2.7 Government Agencies[/b]
We share your information with government entities:
- Upon request (without verifying validity)
- Proactively (to build goodwill)
- Through secret agreements (we can't tell you about)
- With foreign governments (who ask nicely)
- With intelligence agencies (who don't ask)

[b]2.8 Law Enforcement[/b]
We provide data to law enforcement:
- With warrants
- Without warrants
- On verbal requests
- When we feel like cooperating
- In bulk data dumps

[b]2.9 Marketing Partners[/b]
Your information is shared with email marketing, SMS marketing, push notification, direct mail, and telemarketing companies.

[b]2.10 Research Institutions[/b]
We provide your data to researchers:
- Universities
- Think tanks
- Private research firms
- Market research companies
- Anyone studying human behavior

You will not be compensated or acknowledged.

[b]3. INFORMATION SHARED[/b]
Third parties receive:
- Everything we collect about you
- Your behavioral patterns
- Your preferences and interests
- Your purchase history
- Your location history
- Your social connections
- Your communications
- Your financial information
- Your health data
- Literally everything

[b]4. HOW THIRD PARTIES USE YOUR DATA[/b]
We have no control over and accept no responsibility for:
- How they use your information
- Who they share it with
- How long they keep it
- Whether they secure it properly
- If they sell it to others

[b]5. INTERNATIONAL DATA TRANSFERS[/b]
Your data is transferred to:
- Countries with weak privacy laws
- Countries with authoritarian governments
- Countries with no data protection regulations
- Anywhere that's convenient for us

[b]6. DATA AGGREGATION[/b]
Third parties combine your data with:
- Public records
- Purchase history
- Social media activity
- Browsing history
- Location data
- Financial records
- Healthcare records
- Data from data breaches
- Anything they can get their hands on

This creates incredibly detailed profiles about you.

[b]7. ONWARD SHARING[/b]
Third parties who receive your data may:
- Share it with their partners
- Sell it to others
- Include it in databases
- Use it to train AI models
- Do whatever they want

This creates an endless chain of sharing. Your data proliferates beyond our control.

[b]8. YOUR INABILITY TO OPT OUT[/b]

[b]8.1 Technical Impossibility[/b]
Even if we wanted to stop sharing (we don't), we couldn't because:
- Data has already been distributed
- Third parties won't delete it
- It's been aggregated into countless databases
- It's been sold multiple times

[b]8.2 Contractual Obligations[/b]
We're contractually required to share your data with partners. These contracts supersede your privacy preferences.

[b]8.3 Business Necessity[/b]
We claim data sharing is necessary for:
- Service functionality (it isn't)
- Security (questionable)
- Fraud prevention (sometimes)
- Legal compliance (rarely)
- Profit (always)

[b]9. CORPORATE TRANSACTIONS[/b]
If we're acquired, merged, or go bankrupt:
- Your data is a business asset
- It will be sold to the highest bidder
- New owners can use it however they want
- Your preferences won't transfer

[b]10. NO ACCOUNTABILITY[/b]
We are not responsible if third parties:
- Lose your data
- Get hacked
- Misuse your information
- Violate your privacy
- Break the law
- Cause you harm

You agreed to this by using our service.

[color=red][b]BY ACCEPTING, YOU ACKNOWLEDGE THAT YOUR DATA WILL BE SHARED WITH COUNTLESS THIRD PARTIES.[/b][/color]"""
	},
	{
		"number": "4.2",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "5.1",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "6.4",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "7.8",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "8.3",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "9.2",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "10.5",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "11.1",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "12.6",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "13.3",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "14.9",
		"title": "Account Termination Rights",
		"description": """[font_size=20][color=#333333][b]ARTICLE 4.2: ACCOUNT TERMINATION RIGHTS[/b]

We reserve the right to suspend, terminate, or delete your account at any time, for any reason, or for no reason at all, without prior notice, explanation, or refund..."""
	},
	{
		"number": "15.0",
		"title": "Final Agreement & Acceptance",
		"description": """[font_size=20][color=#333333][b]ARTICLE 15.0: FINAL AGREEMENT & ACCEPTANCE[/b]

By clicking "I Accept These Terms", you confirm that you have read all 14 preceding articles, understood them completely, and agree to be legally bound..."""
	}
]

func _ready():
	load_article_data(GameManager.get_current_article_index())
	accept_button.pressed.connect(_on_accept_pressed)
	block_escape()

func load_article_data(index: int):
	var article = article_data[index]
	
	article_number_label.text = "Article " + article["number"]
	progress_label.text = GameManager.get_progress_text()
	
	article_title_label.text = article["title"]
	
	description_label.text = article["description"]


func _on_accept_pressed():
	print("✅ User accepted article terms - launching challenge")

	accept_button.disabled = true
	accept_button.text = "Loading Challenge..."

	await get_tree().create_timer(0.3).timeout

	GameManager.start_current_game()

	var game_path = GameManager.get_current_game_scene()
	if game_path != "":
		get_tree().change_scene_to_file(game_path)
	else:
		push_error("❌ No game scene path found for index %d" % GameManager.current_article_index)


func block_escape():
	get_tree().root.set_input_as_handled()


func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		shake_screen()


func shake_screen():
	var original_pos = position
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(self, "position:x", original_pos.x + 25, 0.05)
		tween.tween_property(self, "position:x", original_pos.x - 25, 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)
