/// Phone country prefixes and related constants
library;

const List<String> phonePrefixOptions = [
  '+91', // India (Primary default)
  '+1', // United States / Canada
  '+44', // United Kingdom
  '+971', // United Arab Emirates
  '+93', // Afghanistan
  '+355', // Albania
  '+213', // Algeria
  '+1 684', // American Samoa
  '+376', // Andorra
  '+244', // Angola
  '+1 264', // Anguilla
  '+1 268', // Antigua and Barbuda
  '+54', // Argentina
  '+374', // Armenia
  '+297', // Aruba
  '+61', // Australia
  '+43', // Austria
  '+994', // Azerbaijan
  '+1 242', // Bahamas
  '+973', // Bahrain
  '+880', // Bangladesh
  '+1 246', // Barbados
  '+375', // Belarus
  '+32', // Belgium
  '+501', // Belize
  '+229', // Benin
  '+1 441', // Bermuda
  '+975', // Bhutan
  '+591', // Bolivia
  '+599', // Bonaire, Sint Eustatius and Saba / Curaçao
  '+387', // Bosnia and Herzegovina
  '+267', // Botswana
  '+55', // Brazil
  '+1 284', // British Virgin Islands
  '+673', // Brunei Darussalam
  '+359', // Bulgaria
  '+226', // Burkina Faso
  '+257', // Burundi
  '+238', // Cabo Verde
  '+855', // Cambodia
  '+237', // Cameroon
  '+1 345', // Cayman Islands
  '+236', // Central African Rep.
  '+235', // Chad
  '+56', // Chile
  '+86', // China
  '+57', // Colombia
  '+269', // Comoros
  '+242', // Congo (Rep. of the)
  '+682', // Cook Islands
  '+506', // Costa Rica
  '+225', // Côte d'Ivoire
  '+385', // Croatia
  '+53', // Cuba
  '+357', // Cyprus
  '+420', // Czech Rep.
  '+850', // Dem. People's Rep. of Korea
  '+243', // Dem. Rep. of the Congo
  '+45', // Denmark
  '+246', // Diego Garcia
  '+253', // Djibouti
  '+1 767', // Dominica
  '+1 809', // Dominican Rep.
  '+1 829', // Dominican Rep.
  '+1 849', // Dominican Rep.
  '+593', // Ecuador
  '+20', // Egypt
  '+503', // El Salvador
  '+240', // Equatorial Guinea
  '+291', // Eritrea
  '+372', // Estonia
  '+268', // Eswatini
  '+251', // Ethiopia
  '+500', // Falkland Islands (Malvinas)
  '+298', // Faroe Islands
  '+679', // Fiji
  '+358', // Finland
  '+33', // France
  '+262', // French Indian Ocean
  '+594', // French Guiana
  '+689', // French Polynesia
  '+241', // Gabon
  '+220', // Gambia
  '+995', // Georgia
  '+49', // Germany
  '+233', // Ghana
  '+350', // Gibraltar
  '+30', // Greece
  '+299', // Greenland
  '+1 473', // Grenada
  '+590', // Guadeloupe
  '+1 671', // Guam
  '+502', // Guatemala
  '+224', // Guinea
  '+245', // Guinea-Bissau
  '+592', // Guyana
  '+509', // Haiti
  '+504', // Honduras
  '+852', // Hong Kong, China
  '+36', // Hungary
  '+354', // Iceland
  '+62', // Indonesia
  '+98', // Iran (Islamic Republic of)
  '+964', // Iraq
  '+353', // Ireland
  '+972', // Israel
  '+39', // Italy
  '+1 876', // Jamaica
  '+1 658', // Jamaica
  '+81', // Japan
  '+962', // Jordan
  '+7', // Kazakhstan / Russian Federation
  '+254', // Kenya
  '+686', // Kiribati
  '+82', // Korea (Rep. of)
  '+383', // Kosovo*
  '+965', // Kuwait
  '+996', // Kyrgyzstan
  '+856', // Lao P.D.R.
  '+371', // Latvia
  '+961', // Lebanon
  '+266', // Lesotho
  '+231', // Liberia
  '+218', // Libya
  '+423', // Liechtenstein
  '+370', // Lithuania
  '+352', // Luxembourg
  '+853', // Macao, China
  '+261', // Madagascar
  '+265', // Malawi
  '+60', // Malaysia
  '+960', // Maldives
  '+223', // Mali
  '+356', // Malta
  '+692', // Marshall Islands
  '+596', // Martinique
  '+222', // Mauritania
  '+230', // Mauritius
  '+52', // Mexico
  '+691', // Micronesia
  '+373', // Moldova
  '+377', // Monaco
  '+976', // Mongolia
  '+382', // Montenegro
  '+1 664', // Montserrat
  '+212', // Morocco
  '+258', // Mozambique
  '+95', // Myanmar
  '+264', // Namibia
  '+674', // Nauru
  '+977', // Nepal
  '+31', // Netherlands
  '+687', // New Caledonia
  '+64', // New Zealand
  '+505', // Nicaragua
  '+227', // Niger
  '+234', // Nigeria
  '+683', // Niue
  '+672', // Norfolk Island
  '+389', // North Macedonia
  '+1 670', // Northern Mariana Islands
  '+47', // Norway
  '+968', // Oman
  '+92', // Pakistan
  '+680', // Palau
  '+970', // Palestine, State of
  '+507', // Panama
  '+675', // Papua New Guinea
  '+595', // Paraguay
  '+51', // Peru
  '+63', // Philippines
  '+48', // Poland
  '+351', // Portugal
  '+1 787', // Puerto Rico
  '+1 939', // Puerto Rico
  '+974', // Qatar
  '+40', // Romania
  '+250', // Rwanda
  '+290', // Saint Helena
  '+247', // Ascension
  '+1 869', // Saint Kitts and Nevis
  '+1 758', // Saint Lucia
  '+508', // Saint Pierre and Miquelon
  '+1 784', // Saint Vincent and the Grenadines
  '+685', // Samoa
  '+378', // San Marino
  '+239', // Sao Tome and Principe
  '+966', // Saudi Arabia
  '+221', // Senegal
  '+381', // Serbia
  '+248', // Seychelles
  '+232', // Sierra Leone
  '+65', // Singapore
  '+1 721', // Sint Maarten
  '+421', // Slovakia
  '+386', // Slovenia
  '+677', // Solomon Islands
  '+252', // Somalia
  '+27', // South Africa
  '+211', // South Sudan
  '+34', // Spain
  '+94', // Sri Lanka
  '+249', // Sudan
  '+597', // Suriname
  '+46', // Sweden
  '+41', // Switzerland
  '+963', // Syrian Arab Republic
  '+886', // Taiwan, China
  '+992', // Tajikistan
  '+255', // Tanzania
  '+66', // Thailand
  '+670', // Timor-Leste
  '+228', // Togo
  '+690', // Tokelau
  '+676', // Tonga
  '+1 868', // Trinidad and Tobago
  '+216', // Tunisia
  '+90', // Türkiye
  '+993', // Turkmenistan
  '+1 649', // Turks and Caicos
  '+688', // Tuvalu
  '+256', // Uganda
  '+380', // Ukraine
  '+1 340', // US Virgin Islands
  '+598', // Uruguay
  '+998', // Uzbekistan
  '+678', // Vanuatu
  '+58', // Venezuela
  '+84', // Viet Nam
  '+681', // Wallis and Futuna
  '+967', // Yemen
  '+260', // Zambia
  '+263', // Zimbabwe
  '+882 37', // AT&T Cingular
  '+881 8', // Globalstar
  '+881 9', // Globalstar
  '+870', // Inmarsat
  '+881 6', // Iridium
  '+881 7', // Iridium
  '+882 32', // MCP
  '+882 16', // Thuraya
];

const Map<String, String> phonePrefixLabels = {
  '+91': '🇮🇳 India (+91)',
  '+1': '🇺🇸 United States (+1)',
  '+44': '🇬🇧 United Kingdom (+44)',
  '+971': '🇦🇪 United Arab Emirates (+971)',
  '+93': '🇦🇫 Afghanistan (+93)',
  '+355': '🇦🇱 Albania (+355)',
  '+213': '🇩🇿 Algeria (+213)',
  '+1 684': '🇦🇸 American Samoa (+1 684)',
  '+376': '🇦🇩 Andorra (+376)',
  '+244': '🇦🇴 Angola (+244)',
  '+1 264': '🇦🇮 Anguilla (+1 264)',
  '+1 268': '🇦🇬 Antigua and Barbuda (+1 268)',
  '+54': '🇦🇷 Argentina (+54)',
  '+374': '🇦🇲 Armenia (+374)',
  '+297': '🇦🇼 Aruba (+297)',
  '+61': '🇦🇺 Australia (+61)',
  '+43': '🇦🇹 Austria (+43)',
  '+994': '🇦🇿 Azerbaijan (+994)',
  '+1 242': '🇧🇸 Bahamas (+1 242)',
  '+973': '🇧🇭 Bahrain (+973)',
  '+880': '🇧🇩 Bangladesh (+880)',
  '+1 246': '🇧🇧 Barbados (+1 246)',
  '+375': '🇧🇾 Belarus (+375)',
  '+32': '🇧🇪 Belgium (+32)',
  '+501': '🇧🇿 Belize (+501)',
  '+229': '🇧🇯 Benin (+229)',
  '+1 441': '🇧🇲 Bermuda (+1 441)',
  '+975': '🇧🇹 Bhutan (+975)',
  '+591': '🇧🇴 Bolivia (+591)',
  '+599': '🇨🇼 Bonaire/Curaçao (+599)',
  '+387': '🇧🇦 Bosnia and Herzegovina (+387)',
  '+267': '🇧🇼 Botswana (+267)',
  '+55': '🇧🇷 Brazil (+55)',
  '+1 284': '🇻🇬 British Virgin Islands (+1 284)',
  '+673': '🇧🇳 Brunei Darussalam (+673)',
  '+359': '🇧🇬 Bulgaria (+359)',
  '+226': '🇧🇫 Burkina Faso (+226)',
  '+257': '🇧🇮 Burundi (+257)',
  '+238': '🇨🇻 Cabo Verde (+238)',
  '+855': '🇰🇭 Cambodia (+855)',
  '+237': '🇨🇲 Cameroon (+237)',
  '+1 345': '🇰🇾 Cayman Islands (+1 345)',
  '+236': '🇨🇫 Central African Rep. (+236)',
  '+235': '🇹🇩 Chad (+235)',
  '+56': '🇨🇱 Chile (+56)',
  '+86': '🇨🇳 China (+86)',
  '+57': '🇨🇴 Colombia (+57)',
  '+269': '🇰🇲 Comoros (+269)',
  '+242': '🇨🇬 Congo (Rep. of the) (+242)',
  '+682': '🇨🇰 Cook Islands (+682)',
  '+506': '🇨🇷 Costa Rica (+506)',
  '+225': '🇨🇮 Côte d\'Ivoire (+225)',
  '+385': '🇭🇷 Croatia (+385)',
  '+53': '🇨🇺 Cuba (+53)',
  '+357': '🇨🇾 Cyprus (+357)',
  '+420': '🇨🇿 Czech Rep. (+420)',
  '+850': '🇰🇵 Dem. People\'s Rep. of Korea (+850)',
  '+243': '🇨🇩 Dem. Rep. of the Congo (+243)',
  '+45': '🇩🇰 Denmark (+45)',
  '+246': '🇮🇴 Diego Garcia (+246)',
  '+253': '🇩🇯 Djibouti (+253)',
  '+1 767': '🇩🇲 Dominica (+1 767)',
  '+1 809': '🇩🇴 Dominican Rep. (+1 809)',
  '+1 829': '🇩🇴 Dominican Rep. (+1 829)',
  '+1 849': '🇩🇴 Dominican Rep. (+1 849)',
  '+593': '🇪🇨 Ecuador (+593)',
  '+20': '🇪🇬 Egypt (+20)',
  '+503': '🇸🇻 El Salvador (+503)',
  '+240': '🇬🇶 Equatorial Guinea (+240)',
  '+291': '🇪🇷 Eritrea (+291)',
  '+372': '🇪🇪 Estonia (+372)',
  '+268': '🇸🇿 Eswatini (+268)',
  '+251': '🇪🇹 Ethiopia (+251)',
  '+500': '🇫🇰 Falkland Islands (+500)',
  '+298': '🇫🇴 Faroe Islands (+298)',
  '+679': '🇫🇯 Fiji (+679)',
  '+358': '🇫🇮 Finland (+358)',
  '+33': '🇫🇷 France (+33)',
  '+262': '🇷🇪 French Indian Ocean (+262)',
  '+594': '🇬🇫 French Guiana (+594)',
  '+689': '🇵🇫 French Polynesia (+689)',
  '+241': '🇬🇦 Gabon (+241)',
  '+220': '🇬🇲 Gambia (+220)',
  '+995': '🇬🇪 Georgia (+995)',
  '+49': '🇩🇪 Germany (+49)',
  '+233': '🇬🇭 Ghana (+233)',
  '+350': '🇬🇮 Gibraltar (+350)',
  '+30': '🇬🇷 Greece (+30)',
  '+299': '🇬🇱 Greenland (+299)',
  '+1 473': '🇬🇩 Grenada (+1 473)',
  '+590': '🇬🇵 Guadeloupe (+590)',
  '+1 671': '🇬🇺 Guam (+1 671)',
  '+502': '🇬🇹 Guatemala (+502)',
  '+224': '🇬🇳 Guinea (+224)',
  '+245': '🇬🇼 Guinea-Bissau (+245)',
  '+592': '🇬🇾 Guyana (+592)',
  '+509': '🇭🇹 Haiti (+509)',
  '+504': '🇭🇳 Honduras (+504)',
  '+852': '🇭🇰 Hong Kong, China (+852)',
  '+36': '🇭🇺 Hungary (+36)',
  '+354': '🇮🇸 Iceland (+354)',
  '+62': '🇮🇩 Indonesia (+62)',
  '+98': '🇮🇷 Iran (+98)',
  '+964': '🇮🇶 Iraq (+964)',
  '+353': '🇮🇪 Ireland (+353)',
  '+972': '🇮🇱 Israel (+972)',
  '+39': '🇮🇹 Italy (+39)',
  '+1 876': '🇯🇲 Jamaica (+1 876)',
  '+1 658': '🇯🇲 Jamaica (+1 658)',
  '+81': '🇯🇵 Japan (+81)',
  '+962': '🇯🇴 Jordan (+962)',
  '+7': '🇰🇿 Kazakhstan / 🇷🇺 Russia (+7)',
  '+254': '🇰🇪 Kenya (+254)',
  '+686': '🇰🇮 Kiribati (+686)',
  '+82': '🇰🇷 Korea (Rep. of) (+82)',
  '+383': '🇽🇰 Kosovo* (+383)',
  '+965': '🇰🇼 Kuwait (+965)',
  '+996': '🇰🇬 Kyrgyzstan (+996)',
  '+856': '🇱🇦 Lao P.D.R. (+856)',
  '+371': '🇱🇻 Latvia (+371)',
  '+961': '🇱🇧 Lebanon (+961)',
  '+266': '🇱🇸 Lesotho (+266)',
  '+231': '🇱🇷 Liberia (+231)',
  '+218': '🇱🇾 Libya (+218)',
  '+423': '🇱🇮 Liechtenstein (+423)',
  '+370': '🇱🇹 Lithuania (+370)',
  '+352': '🇱🇺 Luxembourg (+352)',
  '+853': '🇲🇴 Macao, China (+853)',
  '+261': '🇲🇬 Madagascar (+261)',
  '+265': '🇲🇼 Malawi (+265)',
  '+60': '🇲🇾 Malaysia (+60)',
  '+960': '🇲🇻 Maldives (+960)',
  '+223': '🇲🇱 Mali (+223)',
  '+356': '🇲🇹 Malta (+356)',
  '+692': '🇲🇭 Marshall Islands (+692)',
  '+596': '🇲🇶 Martinique (+596)',
  '+222': '🇲🇷 Mauritania (+222)',
  '+230': '🇲🇺 Mauritius (+230)',
  '+52': '🇲🇽 Mexico (+52)',
  '+691': '🇫🇲 Micronesia (+691)',
  '+373': '🇲🇩 Moldova (+373)',
  '+377': '🇲🇨 Monaco (+377)',
  '+976': '🇲🇳 Mongolia (+976)',
  '+382': '🇲🇪 Montenegro (+382)',
  '+1 664': '🇲🇸 Montserrat (+1 664)',
  '+212': '🇲🇦 Morocco (+212)',
  '+258': '🇲🇿 Mozambique (+258)',
  '+95': '🇲🇲 Myanmar (+95)',
  '+264': '🇳🇦 Namibia (+264)',
  '+674': '🇳🇷 Nauru (+674)',
  '+977': '🇳🇵 Nepal (+977)',
  '+31': '🇳🇱 Netherlands (+31)',
  '+687': '🇳🇨 New Caledonia (+687)',
  '+64': '🇳🇿 New Zealand (+64)',
  '+505': '🇳🇮 Nicaragua (+505)',
  '+227': '🇳🇪 Niger (+227)',
  '+234': '🇳🇬 Nigeria (+234)',
  '+683': '🇳🇺 Niue (+683)',
  '+672': '🇳🇫 Norfolk Island (+672)',
  '+389': '🇲🇰 North Macedonia (+389)',
  '+1 670': '🇲🇵 N. Mariana Islands (+1 670)',
  '+47': '🇳🇴 Norway (+47)',
  '+968': '🇴🇲 Oman (+968)',
  '+92': '🇵🇰 Pakistan (+92)',
  '+680': '🇵🇼 Palau (+680)',
  '+970': '🇵🇸 Palestine (+970)',
  '+507': '🇵🇦 Panama (+507)',
  '+675': '🇵🇬 Papua New Guinea (+675)',
  '+595': '🇵🇾 Paraguay (+595)',
  '+51': '🇵🇪 Peru (+51)',
  '+63': '🇵🇭 Philippines (+63)',
  '+48': '🇵🇱 Poland (+48)',
  '+351': '🇵🇹 Portugal (+351)',
  '+1 787': '🇵🇷 Puerto Rico (+1 787)',
  '+1 939': '🇵🇷 Puerto Rico (+1 939)',
  '+974': '🇶🇦 Qatar (+974)',
  '+40': '🇷🇴 Romania (+40)',
  '+250': '🇷🇼 Rwanda (+250)',
  '+290': '🇸🇭 Saint Helena (+290)',
  '+247': '🇸🇭 Ascension (+247)',
  '+1 869': '🇰🇳 Saint Kitts and Nevis (+1 869)',
  '+1 758': '🇱🇨 Saint Lucia (+1 758)',
  '+508': '🇵🇲 Saint Pierre and Miquelon (+508)',
  '+1 784': '🇻🇨 St Vincent & Grenadines (+1 784)',
  '+685': '🇼🇸 Samoa (+685)',
  '+378': '🇸🇲 San Marino (+378)',
  '+239': '🇸🇹 Sao Tome and Principe (+239)',
  '+966': '🇸🇦 Saudi Arabia (+966)',
  '+221': '🇸🇳 Senegal (+221)',
  '+381': '🇷🇸 Serbia (+381)',
  '+248': '🇸🇨 Seychelles (+248)',
  '+232': '🇸🇱 Sierra Leone (+232)',
  '+65': '🇸🇬 Singapore (+65)',
  '+1 721': '🇸🇽 Sint Maarten (+1 721)',
  '+421': '🇸🇰 Slovakia (+421)',
  '+386': '🇸🇮 Slovenia (+386)',
  '+677': '🇸🇧 Solomon Islands (+677)',
  '+252': '🇸🇴 Somalia (+252)',
  '+27': '🇿🇦 South Africa (+27)',
  '+211': '🇸🇸 South Sudan (+211)',
  '+34': '🇪🇸 Spain (+34)',
  '+94': '🇱🇰 Sri Lanka (+94)',
  '+249': '🇸🇩 Sudan (+249)',
  '+597': '🇸🇷 Suriname (+597)',
  '+46': '🇸🇪 Sweden (+46)',
  '+41': '🇨🇭 Switzerland (+41)',
  '+963': '🇸🇾 Syrian Arab Republic (+963)',
  '+886': '🇹🇼 Taiwan, China (+886)',
  '+992': '🇹🇯 Tajikistan (+992)',
  '+255': '🇹🇿 Tanzania (+255)',
  '+66': '🇹🇭 Thailand (+66)',
  '+670': '🇹🇱 Timor-Leste (+670)',
  '+228': '🇹🇬 Togo (+228)',
  '+690': '🇹🇰 Tokelau (+690)',
  '+676': '🇹🇴 Tonga (+676)',
  '+1 868': '🇹🇹 Trinidad and Tobago (+1 868)',
  '+216': '🇹🇳 Tunisia (+216)',
  '+90': '🇹🇷 Türkiye (+90)',
  '+993': '🇹🇲 Turkmenistan (+993)',
  '+1 649': '🇹🇨 Turks and Caicos (+1 649)',
  '+688': '🇹🇻 Tuvalu (+688)',
  '+256': '🇺🇬 Uganda (+256)',
  '+380': '🇺🇦 Ukraine (+380)',
  '+1 340': '🇻🇮 US Virgin Islands (+1 340)',
  '+598': '🇺🇾 Uruguay (+598)',
  '+998': '🇺🇿 Uzbekistan (+998)',
  '+678': '🇻🇺 Vanuatu (+678)',
  '+58': '🇻🇪 Venezuela (+58)',
  '+84': '🇻🇳 Viet Nam (+84)',
  '+681': '🇼🇫 Wallis and Futuna (+681)',
  '+967': '🇾🇪 Yemen (+967)',
  '+260': '🇿🇲 Zambia (+260)',
  '+263': '🇿🇼 Zimbabwe (+263)',
  '+882 37': '📡 AT&T Cingular (+882 37)',
  '+881 8': '📡 Globalstar (+881 8)',
  '+881 9': '📡 Globalstar (+881 9)',
  '+870': '📡 Inmarsat (+870)',
  '+881 6': '📡 Iridium (+881 6)',
  '+881 7': '📡 Iridium (+881 7)',
  '+882 32': '📡 MCP (+882 32)',
  '+882 16': '📡 Thuraya (+882 16)',
};

const Map<String, int> phonePrefixMaxDigits = {
  '+91': 10,
  '+1': 10,
  '+44': 10,
  '+61': 9,
  '+971': 9,
  '+65': 8,
  '+60': 10,
  '+66': 9,
  '+81': 10,
  '+82': 10,
  '+86': 11,
  '+49': 11,
  '+33': 9,
  '+39': 10,
  '+34': 9,
  '+7': 10,
};
