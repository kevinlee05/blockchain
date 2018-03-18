from uuid import uuid4
from textwrap import dedent
from flask import Flask, jsonify, request
from blockchain import Blockchain

# Instantiate our Node
app = Flask(__name__)

# Generate a globally unique (random) address (name) for this node
node_identifier = str(uuid4()).replace('-', '')

#instantiate the Blockchain
blockchain = Blockchain()

#Create the /mine endpoint, which is a GET request.
""" The mining endpoint  has to do three things:
1.Calculate the Proof of Work
2.Reward the miner (us) by adding a transaction granting us 1 coin
3.Forge the new Block by adding it to the chain
"""
@app.route('/mine', methods=['GET'])
def mine():
    #we run the proof of work algorithm to get the next proof...
    last_block = blockchain.last_block
    last_proof = last_block['proof']
    proof = blockchain.proof_of_work(last_proof)

    # We must receive a reward for finding the proof.
    # the reward is 1 coin
    # The sender is "0" to signify that this node has mined a new coin.
    blockchain.new_transaction(
        sender="0",
        recipient=node_identifier,
        amount=1,
    )

    # Forge the new Block by adding it to the chain
    previous_hash = blockchain.hash(last_block)
    block = blockchain.new_block(proof, previous_hash)

    response = {
        'message': "New Block Forged",
        'index': block['index'],
        'transactions': block['transactions'],
        'proof': block['proof'],
        'previous_hash': block['previous_hash'],
    }

    return jsonify(response), 200

#Create the /transactions/new endpoint, which is a POST request, since we’ll be sending data to it.
@app.route('/transactions/new', methods=['POST'])
def new_transaction():
    values = request.get_json()

    #check that the required fields are in the POST'ed data
    required = ['sender', 'recipient', 'amount']
    if not all(k in values for k in required):
        return 'Missing values', 400

    #Create a new Transaction
    index = blockchain.new_transaction(values['sender'], values['recipient'], values['amount'])
    response = {'message': f'Transaction will be added to Block{index}'}
    return jsonify(response), 201

#Create the /chain endpoint, which returns the full Blockchain.
@app.route('/chain', methods=['GET'])
def full_chain():
    response = {
        'chain': blockchain.chain,
        'length': len(blockchain.chain),
    }
    return jsonify(response), 200

@app.route('nodes/register', methods=['POST'])
def register_nodes():
    values = request.get_json()
    nodes = values.get('nodes')
    if nodes is None:
        return "Error: Please supply a valid list of nodes", 400

    for node in nodes:
        blockchain.register_node(node)

    response = {
        'message': 'New nodes have been addded',
        'total_nodes': list(blockchain.nodes),
    }
    return jsonify(response), 201

@app.route('/nodes/resolve', methods=['GET'])
def consensus():
    replaced = blockchain.resolve_conflicts()
    #check for conflicts between our blockchain and other blockchains in the network

    if replaced: #if our blockchain has been replaced
        response = {
            'message': 'Our chain was replaced',
            'new_chain': blockchain.chain
        }
    else: #if our blockchain was not replaced
        response = {
            'message': 'Our chain is authoritative',
            'chain': blockchain.chain
        }

    return jsonify(response), 200


#Runs the server on port 5000.
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
