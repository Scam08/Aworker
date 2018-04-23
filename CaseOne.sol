pragma solidity ^0.4.18;

contract RequestPool {
    struct Request {
        address uid;
        string proof;
        string skill;
        address[] yes;
        address[] no;
    }
    
    struct SkillNote {
        string proof;
        address[] yes;
        address[] no;
    }
    mapping(uint => mapping(bool => address[])) kak_progolosoval;
    mapping(uint => mapping(address => bool)) golosa;
    uint idCounter = 0;
    mapping (uint => Request) requests;
    mapping (address => uint) workerReputation;
    uint[] pendingRequestsId;
    
    // uid => skill => SkillNote
    mapping (address => mapping( string => SkillNote ) ) skillNotes;
    
    function AddPendingRequest(string skill, string proof) public returns (uint rid) {
        requests[idCounter].uid = msg.sender;
        requests[idCounter].skill = skill;
        requests[idCounter].proof = proof;
        pendingRequestsId.push(idCounter);
        idCounter++;
        return idCounter - 1;
    }
    
    /*
    function getIdBySkillName(string str) public constant returns (uint[]){
        uint[] a;
        for(var i = 0; i < requests; i++){
            if(str == requests[i].skill){
                a.push(i);
            }
        }
        return a;
    }
    */
    
    function getGolosaById(uint rid) public constant returns (uint){
        return kak_progolosoval[rid][true].length + kak_progolosoval[rid][false].length; 
    }
    
    function getGolosaByIdZa(uint rid) public constant returns (uint){
        return kak_progolosoval[rid][true].length; 
    }
    
    function getGolosaByIdProtiv(uint rid) public constant returns (uint){
        return kak_progolosoval[rid][false].length; 
    }
    function ConfirmRequest(uint rid, bool answer) public returns (bool) {
        if(!_isPending(rid))
        	return false;
        Request storage r = requests[rid];
        
        uint percent = GetSkill(msg.sender, r.skill);
        if (percent < 60)
        	return false;
        
        return _handleVote(rid, answer, msg.sender);
    }
    
    function AddSkill(address uid, string skill, string proof, address[] yes, address[] no) public returns (bool) {
        skillNotes[uid][skill].proof = proof;
        skillNotes[uid][skill].yes = yes;
        skillNotes[uid][skill].no = no;
        return true;
    }
    
    function getNameOfSkill(uint id) public constant returns(string){
        return requests[id].skill;
    }
    
    function getAdressOfSkill(uint id) public constant returns(address){
        return requests[id].uid;
    }
    
    function GetPendingRequestsId() public view returns (uint[]) {
        return pendingRequestsId;
    }
    
    function getName() public constant returns (address){
        return msg.sender;
    }
    
    function GetSkill(address uid, string skill) public view returns (uint percent) {
        percent = 0;
        SkillNote storage sn = skillNotes[uid][skill];
        
        if (sn.yes.length + sn.no.length != 0)
        	return 100 * sn.yes.length / (sn.yes.length + sn.no.length);
        return 0;
    }
    
    function GetUserReputation(address uid) public view returns (uint reputation) {
        return workerReputation[uid];
    }
        
    function _isPending(uint rid) private view returns (bool isPending) {
        for(uint i = 0; i < pendingRequestsId.length; i++) {
            if (pendingRequestsId[i] == rid)
                return true;
        }
        return false;
    }
    
    function _handleVote(uint rid, bool answer, address voterUid) private returns (bool) {
        if(golosa[rid][voterUid] == false){
            golosa[rid][voterUid] = true;
        }
        else
            return false;
        if(answer){
            requests[rid].yes.push(voterUid);
            kak_progolosoval[rid][true].push(voterUid);
        }
        else{
            requests[rid].no.push(voterUid);
            kak_progolosoval[rid][false].push(voterUid);
        }
        return _checkCompleteness(rid);
    }
    
    function _removePendingRequest(uint rid) private returns (bool) {
        for(uint i = 0; i < pendingRequestsId.length; i++) {
            if (pendingRequestsId[i] == rid) {
                for (uint j = i; j < pendingRequestsId.length-1; j++)
                    pendingRequestsId[j] = pendingRequestsId[j+1];
                pendingRequestsId.length--;
            }
        }
        return true;
    }
    
    function getProof(uint rid) public constant returns (string){
        return requests[rid].proof;
    }
    
    function _checkCompleteness(uint rid) private returns (bool) {
        Request storage r = requests[rid];
        if(r.yes.length + r.no.length < 10)
        	return false;
        
        uint yesPercent =100 * r.yes.length / (r.yes.length + r.no.length);
        if (yesPercent <= 40) {
            _removePendingRequest(rid);
            for(uint i = 0; i < kak_progolosoval[rid][false].length; i++){
                workerReputation[kak_progolosoval[rid][false][i]]++;
            }
            return true;
        } 
        else if (yesPercent >= 60) {
            for(uint j = 0; j < kak_progolosoval[rid][true].length; j++){
                workerReputation[kak_progolosoval[rid][true][j]]++;
            }
            AddSkill(r.uid, r.skill, r.proof, r.yes, r.no);
            return true;
        }
        return false;
    }
    
    function _incrementReputation(address uid) private returns (bool) {
        workerReputation[uid]++;
        return true;
    }
}