Config = {}

Config.TaxiModel = `taxi`
Config.PricePerKM = 50 -- Price for the taxi per KM
Config.HurryTip = 50 --amount to pay to make driver go faster
Config.TaxiCommand = "aitaxi" -- command to start taxi ride
Config.TaxiStopCommand = 'stoptaxi'
Config.AutopilotCommand = "autopilot"
Config.AutopilotstopCommand = "autopilotstop"
Config.Fuel = "LegacyFuel" -- name of the resource you use for fuel

Config.AllowHurryMode = true -- press E when in taxi to pay for fast mode
Config.TaxiRelievesStress = 3 --relieves this much stress every minute in a taxi // or false for no stress relief
Config.RequirePhoneItem = true --means you need a phone to be able to use taxi command
Config.Phones = { --the phone item codes
    'phone',
    'black_phone',
    'pink_phone',
    'blue_phone',
    'red_phone',
    'classic_phone',
    'gold_phone',
    'greenlight_phone',
    'green_phone',
    'white_phone',
}

Config.AutoPilotCars = {
    'buffalo5', -- Buffalo evx (Newest gamebuild only(2944))
    'cyclone',
    'cyclone2',
    'iwagen',
    'khamelion',
    'neon',
    'omnisegt',
    'raiden',
    'tezeract',
    'virtue',
    'voltic',
    'surge',
    'dilettante',
}

Config.DriverPeds = { --taxi driver peds
    'ig_priest',
    'a_m_m_eastsa_01',
    'a_m_m_genfat_02',
    'a_m_m_polynesian_01',
    'a_m_m_socenlat_01',
    'a_m_o_genstreet_01',
    'a_m_y_bevhills_01',
    'a_m_y_business_02',
    'a_m_y_hipster_02',
    'a_m_y_soucent_02',
    'a_f_m_prolhost_01',
    'a_f_m_tourist_01',
    'a_f_o_genstreet_01',
    'a_f_o_soucent_01',
    'a_f_y_eastsa_03',
    'a_f_y_vinewood_01',
}
