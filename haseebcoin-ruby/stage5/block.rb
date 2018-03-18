require 'colorize'
require 'digest'

class Block
    NUM_ZEROES = 4
    attr_reader :msg, :prev_block_hash, :block_hash

    def self.create_genesis_block(msg)
        Block.new(nil, msg)
    end

    def initialize(prev_block, msg)
        @msg = msg
        @prev_block_hash = prev_block.block_hash if prev_block
        mine_block!
    end

    def mine_block!
        @nonce = find_nonce()
    end

    private

    def hash(message)
        Digest::SHA256.hexdigest(message)
    end

    def find_nonce(message)
        nonce = "HELP i'm trapped in a nonce factory"
        count = 0

        until is_valid_nonce?(nonce)
            print "." if count % 100_000 == 0
            nonce = nonce.next
            count +=1
        end
        puts count
        nonce
    end

    def block_contents
        [@prev_block_hash, @msg].compact.join
    end

    def is_valid_nonce?(nonce)
        hash(block_contents + nonce).start_with?("0" * NUM_ZEROES)
    end


class BlockChain
    attr_reader :blocks

    def initialize(msg)
        @blocks = [Block.create_genesis_block(msg)]
    end

    def add_to_chain(msg)
        @blocks << Block.new(@blocks.last, msg)
        puts @blocks.last
    end

    def valid?
        #TODO
    end

    def to_s
        @blocks.map(&:to_s).join("\n" )
    end

end

b = BlockChain.new("----GENESIS BLOCK----")
b.add_to_chain("Cinderella")
b.add_to_chain("The Three Stooges")
b.add_to_chain("k-coin-chain")

