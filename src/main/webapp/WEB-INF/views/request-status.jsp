<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<jsp:include page="/WEB-INF/views/common/header.jsp">
    <jsp:param name="title" value="Track Request"/>
    <jsp:param name="nav" value="status"/>
</jsp:include>

<div class="container">
    <div class="page-head">
        <h1>Track your blood request</h1>
        <p class="muted">Enter the request ID you received and the mobile number used in the request.</p>
    </div>

    <form action="${ctx}/request-status" method="get" class="card filter-bar">
        <div class="field">
            <label for="id">Request ID</label>
            <input type="number" id="id" name="id" min="1" required value="<c:out value='${param.id}'/>">
        </div>
        <div class="field">
            <label for="phone">Mobile number</label>
            <input type="tel" id="phone" name="phone" pattern="[0-9]{10}" maxlength="10" required
                   value="<c:out value='${param.phone}'/>">
        </div>
        <button type="submit" class="btn">Check status</button>
    </form>

    <c:if test="${not empty error}">
        <div class="alert alert-error"><c:out value="${error}"/></div>
    </c:if>

    <c:if test="${lookupDone}">
        <c:choose>
            <c:when test="${empty bloodRequest}">
                <div class="alert alert-error">No request found for that ID and mobile number.</div>
            </c:when>
            <c:otherwise>
                <div class="card">
                    <h2>Request #<c:out value="${bloodRequest.id}"/>
                        <span class="badge badge-${bloodRequest.status}"><c:out value="${bloodRequest.status}"/></span>
                    </h2>
                    <dl class="kv">
                        <dt>Patient / requester</dt><dd><c:out value="${bloodRequest.requesterName}"/></dd>
                        <dt>Hospital</dt><dd><c:out value="${bloodRequest.hospital}"/>, <c:out value="${bloodRequest.city}"/></dd>
                        <dt>Blood needed</dt>
                        <dd><span class="badge badge-group"><c:out value="${bloodRequest.bloodGroup}"/></span>
                            &times; <c:out value="${bloodRequest.unitsRequired}"/> unit(s)</dd>
                        <dt>Urgency</dt><dd><span class="badge badge-${bloodRequest.urgency}"><c:out value="${bloodRequest.urgency}"/></span></dd>
                        <dt>Submitted on</dt><dd><fmt:formatDate value="${bloodRequest.requestedOn}" pattern="dd MMM yyyy, HH:mm"/></dd>
                        <c:if test="${not empty bloodRequest.processedOn}">
                            <dt>Last updated</dt><dd><fmt:formatDate value="${bloodRequest.processedOn}" pattern="dd MMM yyyy, HH:mm"/></dd>
                        </c:if>
                        <c:if test="${not empty bloodRequest.adminRemarks}">
                            <dt>Blood bank remarks</dt><dd><c:out value="${bloodRequest.adminRemarks}"/></dd>
                        </c:if>
                    </dl>
                    <p class="muted small" style="margin-top:14px">
                        <strong>PENDING</strong> &ndash; waiting for review &middot;
                        <strong>APPROVED</strong> &ndash; blood reserved, please contact the blood bank &middot;
                        <strong>FULFILLED</strong> &ndash; blood handed over &middot;
                        <strong>REJECTED</strong> &ndash; see remarks.
                    </p>
                </div>
            </c:otherwise>
        </c:choose>
    </c:if>
</div>

<jsp:include page="/WEB-INF/views/common/footer.jsp"/>
