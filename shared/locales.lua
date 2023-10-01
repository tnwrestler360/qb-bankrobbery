local lang = GetConvar('qb_locale', 'en')

Locales = json.decode(LoadResourceFile(Shared.Resource, ('locales/%s.json'):format(lang)))

if not Locales then
    print(('Could not load locales/%s.json'):format(lang))

    Locales = json.decode(LoadResourceFile(Shared.Resource, ('locales/en.json')))
end
