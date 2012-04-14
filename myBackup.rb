#!/usr/bin/ruby

require 'ping'
require 'net/ssh'
require 'net/sftp'

#============================= OPTIONS ==============================#

SCRIPT_VERSION = '1.2.0'


# == General Options for the backup.

FOLDERS        = ['/volumes/business/buchhaltung',
                  '/volumes/business/referenzen', 
                  '/volumes/business/assets', 
                  '/volumes/business/vhs', 
                  '/volumes/business/snippets', 
                  '/volumes/business/fonts', 
                  '/volumes/stuff/studium/"Electronic Business"/seminararbeiten',
                  '/volumes/stuff/dokumente']
               
EMAILS         = '/volumes/stuff/dropbox/backup/mails'


# == Options for the remote machine.

SSH_USER       = 'antonios'
SSH_SERVER     = 'fornax.uberspace.de'
BACKUP_ROOT    = 'files/backups'
BACKUP_DIR     = BACKUP_ROOT + '/bkp_' + Time.now.strftime('%Y_%m_%d')


# == Options for rsync.

RSYNC_OPTIONS  = "-avz --delete --exclude='.DS_Store'"

#========================== END OF OPTIONS ==========================#


#============================= METHODS ==============================#

def createBackup()
   FOLDERS.each do |folder|
      puts "\n" + folder + "\n"
      system("rsync #{RSYNC_OPTIONS} " + folder + " #{SSH_USER}@#{SSH_SERVER}:#{BACKUP_DIR}")
   end
   puts "\n" + EMAILS + "\n"
   system("rsync #{RSYNC_OPTIONS} " + EMAILS + " #{SSH_USER}@#{SSH_SERVER}:#{BACKUP_ROOT}")
end

#========================== END OF METHODS ==========================#


#=============================== MAIN ===============================#

if Ping.pingecho("#{SSH_USER}.#{SSH_SERVER}", 5)
   Net::SSH.start("#{SSH_SERVER}", "#{SSH_USER}") do |ssh|
      ssh.sftp.connect do |sftp|
         START_TIME = Time.now
         puts "\nBackup started...\n"
         createBackup
         puts "\nStarted running at:  #{START_TIME}\n"
         puts "Finished running at: #{Time.now} - Duration: #{"%.0f" % ((Time.now - START_TIME)/60)} min, #{"%.0f" % ((Time.now - START_TIME) % 60)} sec\n"
         current_backups = sftp.dir.entries("/home/#{SSH_USER}/#{BACKUP_ROOT}")
         puts "You have currently " + (current_backups.size-3).to_s() + " backup(s) on your server.\n"
      end
   end
   puts "Version " + SCRIPT_VERSION + "\n\n"
else
   puts "\nConnection to server failed. Please try again later...\n\n"
end