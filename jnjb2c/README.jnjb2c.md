jnjb2c README
===============

1. Follow instructions in README.md

2. The local development environment domain is configured via hostsupdater in 'Vagrantfile'.

        config.hostsupdater.aliases = [
        ¦ "local.acuvue.co.uk",
        ¦ "local.acuvue.ru",
        ¦ "local.de.acuvue.ch",
        ¦ "local.fr.acuvue.ch",
        ¦ "local.it.acuvue.ch",
        ]

    To add a new sub-site, just 'prefix' the domain with 'local.', no need to add
    'local.acuvue.*' as symlinks, Drupal will automatically figure out the correct 
    site directory to use.

3. Use `sites/*/settings.local.php` to override the `settings.php`, e.g. database URI.

    This fill is ignored by Git, so please configure your local settings here.

4. Files is no longer managed by Git, please sync the files with other tools as needed.

5. The configuration of the development environment is managed through 'Puppet' inside
'puppet/' direcotry. Any modification of the environment should be done through code
then provison to the virtualbox. To apply new changes inside 'puppet/', just run
`vagrant reload --provision`.
