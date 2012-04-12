#!/usr/bin/ruby

#============================= OPTIONS ==============================#

SCRIPT_VERSION = '1.0.0'


# == General Options for the backup.

FOLDERS       = ['/volumes/business/buchhaltung',
                 '/volumes/business/referenzen', 
                 '/volumes/business/assets', 
                 '/volumes/business/vhs', 
                 '/volumes/business/snippets', 
                 '/volumes/business/fonts', 
                 '/volumes/stuff/studium/"Electronic Business"/seminararbeiten',
                 '/volumes/stuff/dokumente']
               
EMAILS        = '/volumes/stuff/dropbox/backup/mails'


# == Options for the remote machine.

SSH_USER      = 'someUser'
SSH_SERVER    = 'some.server.de'
BACKUP_ROOT   = 'files/backups'
BACKUP_DIR    = BACKUP_ROOT + '/bkp_' + Time.now.strftime('%Y_%m_%d')


# == Options for rsync.

RSYNC_OPTIONS = "-avz --delete --exclude='.DS_Store'"

#========================== END OF OPTIONS ==========================#

def backup()
   FOLDERS.each do |folder|
   	puts "\n" + folder + "\n"
      system("rsync #{RSYNC_OPTIONS} " + folder + " #{SSH_USER}@#{SSH_SERVER}:#{BACKUP_DIR}")
   end
   system("rsync #{RSYNC_OPTIONS} " + EMAILS + " #{SSH_USER}@#{SSH_SERVER}:#{BACKUP_ROOT}")
end

START_TIME = Time.now
puts "\nBackup started...\n"
backup
puts "\nStarted running at:  #{START_TIME}\n"
puts "Finished running at: #{Time.now} - Duration: #{"%.0f" % ((Time.now - START_TIME)/60)} min, #{"%.0f" % ((Time.now - START_TIME) % 60)} sec\n"
puts "Version " + SCRIPT_VERSION + "\n\n"