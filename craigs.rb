require 'rss'
require 'open-uri'
require 'pony'

class CraigslistAptScraper
  
  def run
    search_url = gather_info
    puts "searching ..."
    link_results_hash = extract_rss_link_info(search_url) # { :post_title => :post_url }
    if link_results_hash
      link_results_hash.keys.each { |title| puts title + "\n ---" }
      array_of_email_addresses = collect_emails(link_results_hash.values).compact!
    
      puts "emailing your matches ..."
    
      email_posters(array_of_email_addresses) 
      
    else
       puts "Sorry, no results found..."
     end
  end
  
  def gather_info
    puts "---------\n Automated BOULDER Apartment Finder \n---------"
    puts ""
    print "Please enter minimum Price: "
    min_price = gets.chomp
    print "Please enter maximum Price: "
    max_price = gets.chomp
    print "Please enter # of bedrooms: "
    beds = gets.chomp
    print "Please enter any specific search terms (or leave blank): "
    search_terms = gets.chomp.split.join('+')
    print "Please enter your gmail address: "
    @sender_address = gets.chomp
    print "Please enter your gmail password: "
    @sender_password = gets.chomp
    url = "http://boulder.craigslist.org/search/hhh?query=#{search_terms}&srchType=A&minAsk=#{min_price}&maxAsk=#{max_price}&bedrooms=#{beds}&format=rss"
    return url
  end
  
  def extract_rss_link_info(search_url)
    results_hash = {}
    open(search_url) do |rss_content|
    
      begin 
        parsed_rss = RSS::Parser.parse(rss_content)
      rescue
        return
      end
      
      parsed_rss.items.each { |item| results_hash[item.title] = item.link }
    end
    
    results_hash

  end
  
  def collect_emails(array_of_posting_urls)
    
    array_of_posting_urls.inject([]) do |array, posting_url|
      array << open(posting_url) do |posting_html|
        match = posting_html.read.match("mailto:")
        (email_addr = match.post_match.match(/[?]/).pre_match) if match
      end
    end
        
  end
  
  def email_posters(array_of_email_addresses)
    if array_of_email_addresses
      array_of_email_addresses.each do |email|
        puts "..."
        puts email + "\n..."
        send_email(email, "Regarding your listing on Craigslist", "Hi, I'm looking for a place to live in the area. Would it be possible to set up a time to come by and have a look? Thanks so much!") if email
      end
    end  
  end
  
  def send_email(to, subject, body)
    begin
      Pony.mail(  :to => to,
                :subject => subject,
                :body => body,
                :via => :smtp,
                :via_options => {
                    :address              => 'smtp.gmail.com',
                    :port                 => '587',
                    :enable_starttls_auto => true,
                    :user_name            => @sender_address,
                    :password             => @sender_password,
                    :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
                    :domain               => "HELO" # the HELO domain provided by the client to the server
                }
              )
    rescue
      puts "Sorry, unable to login to #{@sender_address}"        
    end
  end
end

CraigslistAptScraper.new.run