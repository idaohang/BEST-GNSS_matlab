function trackResult = trackResult_clean(trackResult)
% ������ٽ���еĿհ׿ռ�

n = trackResult.n;

trackResult.dataIndex(n:end,:)    = [];
trackResult.remCodePhase(n:end,:) = [];
trackResult.codeFreq(n:end,:)     = [];
trackResult.remCarrPhase(n:end,:) = [];
trackResult.carrFreq(n:end,:)     = [];
trackResult.I_Q(n:end,:)          = [];
trackResult.disc(n:end,:)         = [];

end