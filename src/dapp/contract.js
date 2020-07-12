import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {
        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = ['Air1', 'Air2', 'Air3', 'Air4', 'Air5'];
        this.passengers = ['PAS1', 'PAS2', 'PAS3', 'PAS4', 'PAS5'];
        this.flights = {
            'Air1': ['FL1', 'FL2', 'FL3'],
            'Air2': ['AL1', 'AL2', 'AL3'],
            'Air3': ['BL1', 'BL2', 'BL3'],
            'Air4': ['CL1', 'CL2', 'CL3'],
            'Air5': ['DL1', 'DL2', 'DL3'],
        }
    }

    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {
            this.owner = accts[0];
            let counter = 1;

            while (this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while (this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner }, callback);
    }

    fetchFlightStatus(airline, flight, timestamp, callback) {
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: timestamp
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner }, (error, _) => {
                callback(error, payload);
            });
    }

    registerAirline(fromairline, airlinetoregister, callback) {
        let self = this;

        self.flightSuretyApp.methods
            .registerAirline(airlinetoregister.toString(), owner)
            .send({ from: fromairline.toString(), gas: 1000000 }, (error, result) => {
                callback(error, result);
            });
    }

    sendFunds(airline, funds, callback) {
        let self = this;

        const fundsToSend = self.web3.utils.toWei(funds, "ether");
        console.log(fundsToSend);
        self.flightSuretyApp.methods
            .fundAirline()
            .send({ from: airline.toString(), value: fundsToSend }, (error, result) => {
                callback(error, result);
            });
    }

    purchaseInsurance(airline, flight, passenger, funds_ether, timestamp, callback) {
        let self = this;

        console.log("airline" + airline);
        const fundstosend1 = self.web3.utils.toWei(funds_ether, "ether");
        console.log(fundstosend1);
        //console.log("passenger buy:" + )
        let ts = timestamp; //1553367808;
        self.flightSuretyApp.methods
            .buyInsurance(airline.toString(), flight.toString(), ts)
            .send({ from: passenger.toString(), value: fundstosend1, gas: 1000 }, (error, result) => {
                callback(error, result);
            });
    }

    withdrawFunds(passenger, callback) {
        let self = this;

        self.flightSuretyApp.methods
            .pay({ from: passenger1, gasPrice: 1000 })
            .send({ from: passenger.toString() }, (error, result) => {
                callback(error, result);
            });
    }

    getBalance(passenger, callback) {
        let self = this;

        self.web3.eth.
        getBalance(passenger1).call({ from: passenger }, (error, result) => {
            callback(error, result);
        });
    }
}