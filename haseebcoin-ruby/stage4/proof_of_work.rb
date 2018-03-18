require 'digest'

NUM_ZEROES = 4

def hash(message)
    Digest::SHA256.hexdigest(message)
end

def find_nonce(message)
    nonce = "HELP i'm trapped in a nonce factory"
    count = 0

    until is_valid_nonce?(nonce, message)
        print "." if count % 100_000 == 0
        nonce = nonce.next
        count +=1
    end
    puts count
    nonce
end

def is_valid_nonce?(nonce, message)
    hash(message + nonce).start_with?("0" * NUM_ZEROES)
end
