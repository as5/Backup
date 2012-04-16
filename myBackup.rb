#!/usr/bin/ruby
 
require 'ping'
require 'net/ssh'
require 'net/sftp'
 
#============================= OPTIONS ==============================#
 
SCRIPT_VERSION = '2.0.0'
 
 
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
 
NO_OF_BACKUPS  = 5


# == Options for the remote machine.
 
SSH_USER       = 'user'
SSH_SERVER     = 'some.server.de'
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
 
# Check server availability by Ping
if Ping.pingecho("#{SSH_USER}.#{SSH_SERVER}", 5)
 
   # Start SSH-session and connecting via SFTP
   Net::SSH.start("#{SSH_SERVER}", "#{SSH_USER}") do |ssh|
      ssh.sftp.connect do |sftp|
         START_TIME = Time.now
         puts "\nBackup started at: #{START_TIME}\n"
 
         # Do backup
         createBackup
 
         # Create @existing_backups with filtering unwanted folders
         existing_backups = sftp.dir.entries("/home/#{SSH_USER}/#{BACKUP_ROOT}").reject do |backup_folder|
            %w(. .. mails).include?(backup_folder.name)
         end
 
         # Sort @existing_backups by name
         existing_backups.sort! { |a,b| a.name <=> b.name }
 
         # Delete old backups if NO_OF_BACKUPS exceeded
         if existing_backups.size > NO_OF_BACKUPS
            puts "\nDeleting old backup...\n"
            ssh.exec!("rm -rf /home/#{SSH_USER}/#{BACKUP_ROOT}/" + existing_backups.first.name)
            backup_deleted = true
            existing_backups.pop
         else
            backup_deleted = false
         end
 
         # Put statistics at the end of the backup
         puts "\nStarted running at:  #{START_TIME}\n"
         puts "Finished running at: #{Time.now} - Duration: #{"%.0f" % ((Time.now - START_TIME)/60)} min, #{"%.0f" % ((Time.now - START_TIME) % 60)} sec\n"
         if backup_deleted == true
            print "1 backup has been deleted, "
         else
            print "No backup has been deleted, "
         end
         puts (existing_backups.size).to_s() + " backup(s) remain(s) on your server.\n"
      end
   end
   puts "Version " + SCRIPT_VERSION + "\n\n"
else
   puts "\nConnection to server failed. Please try again later...\n\n"
end