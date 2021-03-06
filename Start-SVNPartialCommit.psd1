#
# Манифест модуля для модуля "Start-SVNPartialCommit".
#
# Создано: Dr. L. S. Dee
#
# Дата создания: 08.08.2019
#

@{

# Файл модуля сценария или двоичного модуля, связанный с этим манифестом.
RootModule = '.\Start-SVNPartialCommit.psm1'

# Номер версии данного модуля.
ModuleVersion = '0.0.0.0'

# Поддерживаемые выпуски PSEditions
# CompatiblePSEditions = @()

# Уникальный идентификатор данного модуля
GUID = 'eef2345a-1a6f-4390-a062-9221fe6acbad'

# Автор данного модуля
Author = 'Dr. L. S. Dee'

# Компания, создавшая данный модуль, или его поставщик
CompanyName = 'Неизвестно'

# Заявление об авторских правах на модуль
Copyright = '(c) 2019 Dr. L. S. Dee. Все права защищены.'

# Описание функций данного модуля
Description = 'The module allows to split a bunch of changed files in your copy of SVN repository to several commits with defined max count of items in each. The total number of changed items splits into separate SVN changelists.
GitHub: https://github.com/drlsdee/Start-SVNPartialCommit'

# Минимальный номер версии обработчика Windows PowerShell, необходимой для работы данного модуля
PowerShellVersion = '5.0'

# Имя узла Windows PowerShell, необходимого для работы данного модуля
# PowerShellHostName = ''

# Минимальный номер версии узла Windows PowerShell, необходимой для работы данного модуля
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. Это обязательное требование действительно только для выпуска PowerShell, предназначенного для компьютеров.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. Это обязательное требование действительно только для выпуска PowerShell, предназначенного для компьютеров.
# CLRVersion = ''

# Архитектура процессора (нет, X86, AMD64), необходимая для этого модуля
# ProcessorArchitecture = ''

# Модули, которые необходимо импортировать в глобальную среду перед импортированием данного модуля
# RequiredModules = @()

# Сборки, которые должны быть загружены перед импортированием данного модуля
# RequiredAssemblies = @()

# Файлы сценария (PS1), которые запускаются в среде вызывающей стороны перед импортом данного модуля.
# ScriptsToProcess = @()

# Файлы типа (.ps1xml), которые загружаются при импорте данного модуля
# TypesToProcess = @()

# Файлы формата (PS1XML-файлы), которые загружаются при импорте данного модуля
# FormatsToProcess = @()

# Модули для импорта в качестве вложенных модулей модуля, указанного в параметре RootModule/ModuleToProcess
# NestedModules = @()

# В целях обеспечения оптимальной производительности функции для экспорта из этого модуля не используют подстановочные знаки и не удаляют запись. Используйте пустой массив, если нет функций для экспорта.
FunctionsToExport = 'Start-SVNPartialCommit'

# В целях обеспечения оптимальной производительности командлеты для экспорта из этого модуля не используют подстановочные знаки и не удаляют запись. Используйте пустой массив, если нет командлетов для экспорта.
CmdletsToExport = '*'

# Переменные для экспорта из данного модуля
VariablesToExport = '*'

# В целях обеспечения оптимальной производительности псевдонимы для экспорта из этого модуля не используют подстановочные знаки и не удаляют запись. Используйте пустой массив, если нет псевдонимов для экспорта.
AliasesToExport = '*'

# Ресурсы DSC для экспорта из этого модуля
# DscResourcesToExport = @()

# Список всех модулей, входящих в пакет данного модуля
# ModuleList = @()

# Список всех файлов, входящих в пакет данного модуля
FileList = 'Start-SVNPartialCommit.psm1', 'Data\SVNStates.json', 
               'Functions\Escape-StringWithSpaces.ps1', 
               'Functions\Find-SVNClient.ps1', 'Functions\New-SVNCommitString.ps1', 
               'Functions\New-TimeStamp.ps1', 
               'Functions\RedirectConsoleAppOutput.ps1', 
               'Start-SVNPartialCommit.psd1'

# Личные данные для передачи в модуль, указанный в параметре RootModule/ModuleToProcess. Он также может содержать хэш-таблицу PSData с дополнительными метаданными модуля, которые используются в PowerShell.
PrivateData = @{

    PSData = @{

        # Теги, применимые к этому модулю. Они помогают с обнаружением модуля в онлайн-коллекциях.
        # Tags = @()

        # URL-адрес лицензии для этого модуля.
        # LicenseUri = ''

        # URL-адрес главного веб-сайта для этого проекта.
        ProjectUri = 'https://github.com/drlsdee/Start-SVNPartialCommit'

        # URL-адрес значка, который представляет этот модуль.
        # IconUri = ''

        # Заметки о выпуске этого модуля
        # ReleaseNotes = ''

    } # Конец хэш-таблицы PSData

} # Конец хэш-таблицы PrivateData

# Код URI для HelpInfo данного модуля
# HelpInfoURI = ''

# Префикс по умолчанию для команд, экспортированных из этого модуля. Переопределите префикс по умолчанию с помощью команды Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

