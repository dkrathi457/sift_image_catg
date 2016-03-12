% Smooth path given in qMilestones
% input: qMilestones -> nx4 vector of n milestones. 
%        sphereCenter -> 3x1 position of center of spherical obstacle
%        sphereRadius -> radius of obstacle
% output -> qMilestones -> 4xm vector of milestones. A straight-line interpolated
%                    path through these milestones should result in a
%                    collision-free path. You should output a number of
%                    milestones m<=n.
function qMilestonesSmoothed = Q2(rob,qMilestones,sphereCenter,sphereRadius)
disp('/----Smoothing----\');
%Create a 3-link robot for computing position of end of L1
L1(1) = Link([0 0 0 1.571]);
L1(2) = Link([0 0 0 -1.571]);
L1(3) = Link([0 0.4318 0 -1.571]);
rob3Link = SerialLink(L1,'name','robot');

qMilestonesSmoothed = smoothenPath(rob,rob3Link,qMilestones,sphereCenter,sphereRadius);

disp(['        Q1        Q2        Q3        Q4']);
disp(['   -------   -------   -------   -------']);
disp(qMilestonesSmoothed);
disp(['Number Of qMileStones after smoothing: ', num2str(size(qMilestonesSmoothed,1))]);

end
    
function qMilestonesSmoothed = smoothenPath(rob,rob3Link,qMilestones,sphereCenter,sphereRadius)

noOfMilestones = size(qMilestones,1);
qCurr = qMilestones(1,:);
j=2;
for milestoneNum = 1:noOfMilestones
    for nextMilestoneNum = milestoneNum+1:20
        if(nextMilestoneNum>noOfMilestones)
            break;
        end
        
        qErr=( qMilestones(nextMilestoneNum,:)-qMilestones(milestoneNum,:) )/j;
        qNext=qMilestones(milestoneNum,:)+qErr;
        
        for k=1:(j-1)
            [collision] = checkCollision(rob,rob3Link,qNext,sphereCenter,sphereRadius);
            qNext=qNext+qErr;
            x=0;
            if collision.colsn==0
                if (milestoneNum+nextMilestoneNum)==noOfMilestones
                    qCurr = [qCurr ; qMilestones(noOfMilestones,:)];
                    x = 1;
                    milestoneNum=noOfMilestones;
                    break
                end
            else
                j=2;
                qCurr =[ qCurr ; qMilestones(nextMilestoneNum-1,1:4)];
                x=1;
                milestoneNum=nextMilestoneNum-1;
                break
            end
        end
        if x==1
            break
        end
    end
    qMilestonesSmoothed=qCurr;
end
end
    
function [colStruct]=checkCollision(rob,rob3Link,qNear,sphereCenter,sphereRadius)

%Extract joint angles
qNearEF=qNear;
qNearL1=qNear(1:3);

%Extract Positions of the end of the two arms
posNearEF=rob.fkine(qNearEF);posNearEF=posNearEF(1:3,4);
posNearL1=rob3Link.fkine(qNearL1);posNearL1=posNearL1(1:3,4);

%Check if the new configuration denotes a point outside the work-space [-1 1]
for indx=1:1:3
    if abs(posNearEF(indx)) > 1 || abs(posNearL1(indx)) > 1
        colStruct.colsn=1;
        colStruct.EFPos=posCurrEF;
        return;
    end
end

%Check if the arms or EF of the new configuration collide with the obstacle 
pointCollides=checkCollisionAtPoints(posNearEF,posNearL1,sphereCenter,sphereRadius);

    if pointCollides==1
        colStruct.colsn=1;
    else
        colStruct.colsn=0;
    end

colStruct.EFPos=posNearEF;

end


function pointCollides=checkCollisionAtPoints(posNearEF,posNearL1,sphereCenter,sphereRadius)

pointCollides=0;

%Check for the end of the arms colliding with obstacle
if ((norm(posNearL1 - sphereCenter) < sphereRadius) || ...
    (norm(posNearEF - sphereCenter) < sphereRadius) || ...
    (norm((posNearL1+posNearEF) - sphereCenter) < sphereRadius))
    
    pointCollides=1;
else
    %Check for 20 equally spaced points along the arms to check for collision
    for step=0:0.05:1
        %Points along the robot arms itself from joint to joint
        posNearPointsBaseToL1= moveStep([0; 0; 0],posNearL1,step);
        posNearPointsL1ToEF= moveStep(posNearL1,posNearEF,step);
        posNearPointsBaseToEF= moveStep([0; 0; 0],(posNearL1+posNearEF),step);

        %If any of the points on the path or the arm itself are inside the
        %sphere (at <= radius distance to the centre of sphere
        if ((norm(posNearPointsBaseToL1 - sphereCenter)< sphereRadius) || ...
            (norm(posNearPointsL1ToEF - sphereCenter)< sphereRadius) || ...
            (norm(posNearPointsBaseToEF - sphereCenter) < sphereRadius))

            pointCollides=1;
            break;
        else
            continue;
        end
    end
end
end
   

function posNew=moveStep(posA, posB, step)
    %Calculate increment size based on the distance of the points
    increment=(norm(posB-posA) * step);
    %Move a step towards PosB from PosA
    posNew = posA + ( ((posB-posA)/norm(posB-posA)) * increment );
end

